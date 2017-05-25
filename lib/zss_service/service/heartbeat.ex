defmodule ZssService.Service.Heartbeat do
  use GenServer

  @moduledoc """
  This module will handle the heartbeats that have to be sent. Since this should not hinder
  The actual socket, it's extracted to a several module that will be supervised
  """

  @socket_adapter Application.get_env(:zss_service, :socket_adapter)

  alias ZssService.Message
  require Logger

  @doc """
  Starts the heartbeat sender
  This is not a Genserver, and is used in conjunction with Task.Supervisor

  Args:

  - socket: ZMQ Socket\n
  - config: the config, containing sid, identity and heartbeat. Used to route the heartbeat message with the right identity and interval\n
  """
  def start_link(socket, config, identity) do
    Logger.debug(fn -> "START INFO HEARTBEAT" end)
    GenServer.start_link(__MODULE__, {socket, config, identity}, [])
  end

  def init({socket, config, identity}) do
    Process.send_after(self(), {:heartbeat, socket, config, identity}, 100)
    {:ok, []}
  end

  def handle_info({:heartbeat, socket, config, identity}, state) do
    %{heartbeat: heartbeat, sid: sid} = config
    heartbeat_msg = Message.new "SMI", "HEARTBEAT"

    heartbeat_msg = %Message{heartbeat_msg | identity: identity, payload: sid}

    Logger.debug(fn ->
      "Sending #{message.identity} with id #{message.rid} to #{message.address.sid}:#{message.address.sversion}##{message.address.verb}"
    end)
    :ok = @socket_adapter.send(socket, heartbeat_msg |> Message.to_frames)

    #Prepare next heartbeat
    Process.send_after(self(), {:heartbeat, socket, config, identity}, heartbeat)

    {:noreply, state}
  end
end
