defmodule ZssService.Service do
  @moduledoc """
  The worker for ZSS. Started via ServiceSupervisor.
  """

  use GenServer
  alias ZssService.{Heartbeat, Message}
  require Logger

  @not_found "404"

  defmodule StateConfig do
    @moduledoc """
    Struct for the configuration stored in the state, with appropriate defaults
    """
    defstruct [
      broker: "tcp://127.0.0.1:7776",
      heartbeat: 1000,
      sid: nil,
      identity: nil
    ]

    def new(config) do
      Map.merge(%StateConfig{}, config)
    end
  end

  defmodule State do
    @moduledoc """
    Struct to provide easy navigation through the Service's state, with appropriate defaults
    """

    defstruct [
      config: %StateConfig{},
      socket: nil,
      handlers: %{},
      poller: nil,
      supervisor: nil
    ]
  end

  @doc """
  Starts an instance with the given config. Defaults will be applied.

  Args:

  - config: A map containg sid (required), broker, and heartbeat\n
  """
  def start_link(%{sid: sid} = config) when is_binary(sid) do
    GenServer.start_link(__MODULE__, {config, self})
  end

  def init({%{sid: sid} = config, sup}) do
    {:ok, ctx} = :czmq.start_link

    identity = get_identity(sid) |> String.to_charlist
    config = Map.put(config, :identity, identity)

    :czmq.zctx_set_linger(ctx, 0)
    socket = :czmq.zsocket_new(ctx, :dealer)

    #Read about polling and erlang C ports
    poller = :czmq.subscribe_link(socket, [poll_interval: 50])

    state = %State{config: StateConfig.new(config), socket: socket, poller: poller, supervisor: sup}

    #remove any message after closing
    Logger.debug("Assuming identity #{identity}")
    :ok = :czmq.zsocket_set_identity(socket, identity)
    :ok = :czmq.zsocket_connect(socket, state.config.broker)

    #Initiate heartbeats
    {:ok, state}
  end

  @doc """
  Register a verb to this worker. It will respond to the given verb and pass the payload and message
  """
  def add_verb(pid, {verb, module, fun}) when is_atom(fun) and is_binary(verb) do
    Logger.debug("Register verb #{verb} targetted to module #{module}")
    GenServer.call(pid, {:add_verb, {verb, module, fun}})
  end

  @doc """
  Starts the worker. Causes heartbeats to be run and registers itself to the broker
  """
  def run(pid) do
    GenServer.call(pid, :run)
  end

  def handle_call({:add_verb, {verb, module, fun}}, _from, %{handlers: handlers} = state) do
    handlerFn = fn payload, message ->
      apply(module, fun, [payload, message])
    end

    handlers = Map.put(handlers, String.upcase(verb), handlerFn)

    {:reply, :ok, %{state | handlers: handlers}}
  end

  def handle_call(:run, _from, %{config: %{sid: sid, identity: identity} = config, socket: socket, supervisor: sup} = state) do
    register_msg = Message.new "SMI", "UP"
    register_msg = %Message{register_msg | payload: sid, identity: identity}
    :ok = send_request(socket, register_msg)

    #Run in background to be non-blocking and let the ServiceSupervisor handle supervision for us.
    Task.async(fn ->
      ZssService.ServiceSupervisor.start_child(sup, {Heartbeat, :start, [socket, config]})
    end)

    {:reply, :ok, state}
  end

  def handle_info({_poller, msg}, %{handlers: handlers, socket: socket} = state) do
    handle_msg(msg |> Message.parse, socket, handlers)

    {:noreply, state}
  end

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
  Handles REQ messages intended to run a registered verb.
  """
  defp handle_msg(%Message{} = msg, socket, handlers) do
    Logger.info("Received message #{msg.identity} routed to #{msg.address.verb}")

    handler_fn = Map.get(handlers, msg.address.verb)

    case handler_fn do
      handler_fn when is_function(handler_fn) -> #is a function handler
        {:ok, {result, %{status: status}}} = handler_fn.(msg.payload, msg.headers)
        reply = %Message{msg |
          payload: result,
          status: status,
          type: "REP"
        }
        send_reply(socket, reply)
      _ -> #no matching handler found. Default to 404
        reply = %Message{msg |
          status: @not_found,
          type: "REP"
        }
        send_reply(socket, reply)
    end
  end

  defp handle_msg(_, _, _), do: :ok #match all in case, TODO: log

  defp send_reply(socket, message) do
    Logger.info "Sending reply with id #{message.rid} with code #{message.status} to #{message.identity}"
    :czmq.zsocket_send_all(socket, message |> Message.to_frames)
  end

  #TODO DRY
  defp send_request(socket, message) do
    Logger.info "Sending #{message.identity} with id #{message.rid} to #{message.address.sid}:#{message.address.sversion}##{message.address.verb}"
    :czmq.zsocket_send_all(socket, message |> Message.to_frames)
  end

  @doc """
  Constructs the identity frame for routing
  """
  defp get_identity(sid) do
    "#{sid}##{UUID.uuid1()}"
  end

  @doc """
  Cleans up open resources
  """
  def terminate(_reason, %{socket: socket, supervisor: supervisor, poller: poller}) do
    Supervisor.stop(supervisor)
    :czmq.unsubscribe(poller)
    :czmq.zsocket_destroy(socket)
    :normal
  end
end