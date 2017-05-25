defmodule ZssService.Service do
  @moduledoc """
  The worker for ZSS. Started via ServiceSupervisor.
  """

  use GenServer
  alias ZssService.{Heartbeat, Message, Configuration.Config}
  alias ZssService.Service.{State, MessageHandler}
  import ZssService.Error
  require Logger

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
    MessageHandler.handle_msg(msg |> Message.parse, socket, state)

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("Unexpected message found in handle_info: #{inspect msg}")
    {:noreply, state}
  end

  ### Private API

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
end
