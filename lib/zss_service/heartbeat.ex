defmodule ZssService.Heartbeat do
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
  def start(socket, %{sid: sid, identity: identity, heartbeat: heartbeat} = config) do
    heartbeat_msg = Message.new "SMI", "HEARTBEAT"

    heartbeat_msg = %Message{heartbeat_msg | identity: identity, payload: sid}
    :ok = send_request(socket, heartbeat_msg)

    #Todo better mechanism than timers perhaps
    :timer.sleep(heartbeat)
    start(socket, config)
  end

  #TODO DRY
  defp send_request(socket, message) do
    Logger.debug(fn ->
      "Sending #{message.identity} with id #{message.rid} to #{message.address.sid}:#{message.address.sversion}##{message.address.verb}"
    end)

    @socket_adapter.send(socket, message |> Message.to_frames)
  end
end