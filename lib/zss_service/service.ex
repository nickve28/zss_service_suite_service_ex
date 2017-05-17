defmodule ZssService.Service do
  use GenServer
  alias ZssService.Message

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

    #:ok = :czmq.zsocket_set_identity(socket, sid)
    :ok = :czmq.zsocket_connect(socket, broker)

    #Initiate heartbeats
    config = Map.put(config, :identity, get_identity(sid))
    {:ok, %{config: config, socket: socket, handlers: %{}}}
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

  def handle_call(:run, _from, %{config: %{broker: broker, sid: sid, identity: identity}, socket: socket} = state) do
    register_msg = Message.new "SMI", "UP"
    register_msg = %Message{register_msg | payload: sid, identity: identity}
    :ok = send_request(socket, register_msg)

    send(self, :heartbeat)

    {:reply, :ok, state}
  end

  def handle_info(:heartbeat, %{socket: socket, config: %{heartbeat: heartbeat, sid: sid, identity: identity}} = state) do
    heartbeat_msg = Message.new "SMI", "HEARTBEAT"

    heartbeat_msg = %Message{heartbeat_msg | identity: identity, payload: sid}
    :ok = send_request(socket, heartbeat_msg)

    Process.send_after(self, :heartbeat, heartbeat)
    {:noreply, state}
  end

  defp send_request(socket, message) do
    :czmq.zsocket_send_all(socket, message |> Message.to_frames)
  end

  defp get_identity(sid) do
    "#{sid}##{UUID.uuid1()}"
  end
end