defmodule ZssService.Service.Responder do
  use GenServer

  @moduledoc """
  This module will get responses from the socket. The responses will be forwarded to the service pid
  """

  @socket_adapter Application.get_env(:zss_service, :socket_adapter) || ZssService.Adapters.Socket

  alias ZssService.Message
  require Logger

  @doc """
  Starts the heartbeat sender
  This is not a Genserver, and is used in conjunction with Task.Supervisor

  Args:

  - socket: ZMQ Socket\n
  - pid: The pid to send responses to
  """
  def start_link(socket, pid) do
    Logger.debug(fn -> "START RESPONDER" end)
    GenServer.start_link(__MODULE__, {socket, pid}, [])
  end

  def init({socket, pid}) do
    Process.send_after(self(), {:poll, socket, pid}, 100)
    {:ok, []}
  end

  def handle_info({:poll, socket, pid}, state) do
    msg = @socket_adapter.receive(socket)
    send(pid, msg)
    send(self(), {:poll, socket, pid})

    {:noreply, state}
  end
end
