defmodule ZssService.Service do
  @moduledoc """
  The worker for ZSS. Started via ServiceSupervisor.
  """

  use GenServer
  alias ZssService.{Heartbeat, Message, Configuration.Config, Service.State}
  import ZssService.Error
  require Logger

  @success "200"
  @not_found "404"
  @internal "500"
  @socket_adapter Application.get_env(:zss_service, :socket_adapter)
  @service_supervisor Application.get_env(:zss_service, :service_supervisor)

  ### Public API

  @doc """
  Starts an instance with the given config. Defaults will be applied.

  Args:

  - config: A map containg sid (required), broker, and heartbeat\n
  """
  def start_link(%Config{sid: sid} = config) when is_binary(sid) do
    GenServer.start_link(__MODULE__, {config, self})
  end

  @doc """
  Cleans up open resources
  """
  def terminate(_reason, %{socket: socket, supervisor: supervisor, poller: poller}) do
    Logger.info "Worker terminating.."
    @socket_adapter.cleanup(socket, poller)
    Supervisor.stop(supervisor)
    :normal
  end

  ### GenServer API
  def init({%Config{sid: sid} = config, supervisor}) do
    Logger.debug(fn -> "Initializing process with id #{inspect self()}" end)

    sid = sid
    |> String.upcase

    identity = sid
    |> get_identity()
    |> String.to_charlist

    opts = %{type: :dealer, linger: 0}
    socket = @socket_adapter.new_socket(opts)

    #Read about polling and erlang C ports as why I did this
    {:ok, poller} = @socket_adapter.link_to_poller(socket)

    state = %State{config: config, socket: socket, poller: poller, supervisor: supervisor, identity: identity}

    Logger.debug(fn -> "Assuming identity #{identity}" end)
    @socket_adapter.connect(socket, identity, state.config.broker)

    register(socket, sid, identity)
    initiate_heartbeat(socket, state)

    {:ok, state}
  end

  def handle_info({_poller, msg}, %{config: config, socket: socket, supervisor: sup} = state) when is_list(msg) do
    handle_msg(msg |> Message.parse, socket, state)

    {:noreply, state}
  end

  def handle_info(msg, %{poller: poller} = state) do
    Logger.info("#{inspect poller}")

    Logger.warn("Unexpected message found in handle_info: #{inspect msg}")
    {:noreply, state}
  end

  ### Private API

  @doc """
  Handles heartbeat REP
  """
  defp handle_msg(%Message{address: %{verb: "HEARTBEAT"}}, _, _) do
    :ok
  end

  @doc """
  Handles UP REP
  """
  defp handle_msg(%Message{address: %{verb: "UP"}}, _, _) do
    :ok
  end

  @doc """
  Handles DOWN message from SMI
  """
  defp handle_msg(%Message{address: %{verb: "DOWN", sid: "SMI"}}, _, %{supervisor: supervisor}) do
    Logger.info("Shutting down process after DOWN message from SMI..")
    @service_supervisor.stop(supervisor)
  end

  @doc """
  Handles REQ messages intended to run a registered verb.
  """
  defp handle_msg(%Message{type: "REQ"} = msg, socket, %{config: %{handlers: handlers}}) do
    Logger.info("Received message #{msg.identity} routed to #{msg.address.verb}")

    handler_fn = Map.get(handlers, msg.address.verb)

    case handler_fn do
      handler_fn when is_function(handler_fn) -> #is a function handler
        reply = process_result(msg, handler_fn)
        send_reply(socket, reply)
      _ -> #no matching handler found. Default to 404
        reply = %Message{msg |
          status: @not_found,
          type: "REP"
        }
        send_reply(socket, reply)
    end
  end

  @doc "Catch any non matched message and dont crash the process"
  defp handle_msg(msg, _, _) do
    :ok #match all in case, TODO: log
  end

  @doc "Register the service to the broker by sending the SMI:UP message"
  defp register(socket, sid, identity) do
    Logger.debug(fn -> "Registering with broker.." end)
    register_msg = Message.new "SMI", "UP"
    register_msg = %Message{register_msg | payload: sid, identity: identity}
    :ok = send_request(socket, register_msg)
  end

  @doc "Initiate the heartbeat process to send heartbeat in the specified interval"
  defp initiate_heartbeat(socket, state) do
    # Run in background to be non-blocking and let the ServiceSupervisor handle supervision for us.
    Task.async(fn ->
      Logger.debug(fn -> "Starting heartbeat in process #{inspect self()} with heartbeat #{state.config.heartbeat}" end)
      @service_supervisor.start_child(state.supervisor, {Heartbeat, :start_link, [state.socket, state.config, state.identity]})
    end)
  end

  @doc "Send reply to the broker"
  defp send_reply(socket, message) do
    Logger.info "Sending reply with id #{message.rid} with code #{message.status} to #{message.identity}"
    @socket_adapter.send(socket, message |> Message.to_frames)
  end

  #TODO DRY
  @doc "Send request to the worker"
  defp send_request(socket, message) do
    Logger.info "Sending #{message.identity} with id #{message.rid} to #{message.address.sid}:#{message.address.sversion}##{message.address.verb}"
    @socket_adapter.send(socket, message |> Message.to_frames)
  end

  @doc """
  Constructs the identity frame for routing
  """
  defp get_identity(sid) do
    "#{sid}##{UUID.uuid1()}"
  end

  @doc """
  Processes the result that the client specified handler returned, and create the appropriate reply message
  """
  defp process_result(msg, handler_fn) do
    with {:ok, {result, result_message}} <- handler_fn.(msg.payload, to_zss_message(msg)),
         status <- get_status(result_message)
    do
      reply_payload = get_reply_payload(result, status)

      #TODO improve
      is_no_content = result == nil && !error?(status)
      status = case is_no_content do
        true -> 204
        _ -> status
      end

      %Message{msg |
        payload: reply_payload,
        type: "REP",
        status: status |> Integer.to_string
      }
    else
      err -> handle_error(err, msg)
    end
  end

  defp get_reply_payload(result, true) do
    get_error(@internal |> String.to_integer)
  end

  defp get_reply_payload(result, _) do
    result
  end

  @doc """
  Convert a message to ZSS specified headers to send to clients
  """
  defp to_zss_message(%Message{headers: headers}), do: %{headers: headers}

  @doc """
  Get the status of the message, and default to the specified default (or "200")
  Empty strings get converted to the specified default.
  """
  defp get_status(message, default \\ @success) do
    message
    |> Map.get(:status, default)
    |> case do
      "" -> default
      code -> code
    end
    |> String.to_integer
  end

  @doc """
  Handle error replies from handler functions
  """
  defp handle_error(error, msg) do
    {:error, {error_payload, error_message}} = error
    status = get_status(error_message, @internal)
    error = get_error(status)

    %Message{msg |
      payload: error,
      status: status |> Integer.to_string,
      type: "REP"
    }
  end
end
