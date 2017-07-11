defmodule ZssService.Service.Util do
  @moduledoc false

  require Logger
  alias ZssService.Message

  @socket_adapter Application.get_env(:zss_service, :socket_adapter) || ZssService.Adapters.Socket

  @doc "Send request to the worker"
  def send_request(socket, message) do
    Logger.info("Sending #{message.identity} with id #{message.rid} to #{message.address.sid}:#{message.address.sversion}##{message.address.verb}")
    @socket_adapter.send(socket, message |> Message.to_frames)
  end

  @doc "Send reply to the broker"
  def send_reply(socket, message) do
    Logger.info "Sending reply with id #{message.rid} with code #{message.status} to #{message.identity}"
    @socket_adapter.send(socket, message |> Message.to_frames)
  end
end
