defmodule ZssService.Service do
  use GenServer
  alias ZssService.{Heartbeat, Message}
  require Logger

  @moduledoc """
    The worker for ZSS
  """

  @defaults %{
    broker: "tcp://127.0.0.1:7776",
    heartbeat: 1000
  }

  def start_link(%{sid: _} = config) do
    full_config = Map.merge(@defaults, config)

    GenServer.start_link(__MODULE__, full_config)
  end

  def init(%{sid: sid, broker: broker} = config) do
    {:ok, ctx} = :czmq.start_link

    socket = :czmq.zsocket_new(ctx, :dealer)
    :ok = :czmq.zsocket_set_identity(socket, sid |> String.to_charlist)
    :ok = :czmq.zsocket_connect(socket, broker)

    #TODO THINK ABOUT THIS
    #poller + contest + socket should be housed under a single supervisor PER set
    {:ok, poller} = :czmq.subscribe_link(socket, [poll_interval: 100])

    #Initiate heartbeats
    config = Map.put(config, :identity, get_identity(sid))
    {:ok, %{config: config, socket: socket, poller: poller, handlers: %{}}}
  end

  @doc """
    Register a verb to this worker. It will respond to the given verb and pass the payload and message
  """
  def add_verb(pid, {verb, module, fun}) do
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

  def handle_call(:run, _from, %{config: %{broker: broker, sid: sid, identity: identity} = config, socket: socket} = state) do
    register_msg = Message.new "SMI", "UP"
    register_msg = %Message{register_msg | payload: sid, identity: identity}
    :ok = send_request(socket, register_msg)

    #send(self, :heartbeat) #Make async

    #Run in background and let the Task Supervisor handle supervision for us.
    {:ok, supervisor} = Task.Supervisor.start_link()
    Task.Supervisor.start_child(supervisor, Heartbeat, :start, [socket, config])
    #send(self, :listen) #Should be core of this process

    {:reply, :ok, state}
  end

  def handle_info(:heartbeat, %{socket: socket, config: %{heartbeat: heartbeat, sid: sid, identity: identity}} = state) do
    heartbeat_msg = Message.new "SMI", "HEARTBEAT"

    heartbeat_msg = %Message{heartbeat_msg | identity: identity, payload: sid}
    :ok = send_request(socket, heartbeat_msg)

    Process.send_after(self, :heartbeat, heartbeat)
    {:noreply, state}
  end

  def handle_info(:listen, %{socket: socket, poller: poller} = state) do
    #_response = handle_zmq_response(socket, poller)
    send(self, :listen)
    {:noreply, state}
  end

  defp send_request(socket, message) do
    Logger.info "Sending #{message.identity} with id #{message.rid} to #{message.address.sid}:#{message.address.sversion}##{message.address.verb}"
    :czmq.zsocket_send_all(socket, message |> Message.to_frames)
  end

  defp get_identity(sid) do
    "#{sid}##{UUID.uuid1()}"
  end

  defp handle_zmq_response(socket, poller) do
    #Need to make the poll checker non blocking somehow
    receive do
      x -> IO.inspect(x)
    end
    #always :error for some reason...
    #https://github.com/gar1t/erlang-czmq/blob/master/c_src/erl_czmq.c#L641
    #frames = :czmq.zframe_recv_all(socket)
    #Logger.debug("Received response from socket: #{frames}")
    #frames
  end

  def terminate(_reason, %{socket: socket, poller: poller}) do
    :czmq.unsubscribe(poller)
    :czmq.zsocket_destroy(socket)
    :normal
  end
end