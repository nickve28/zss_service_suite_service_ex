defmodule ZssService.Receiver do
  require Logger
  alias ZssService.Message

  def start(socket, callback) do
    case :czmq.zframe_recv_all(socket) do
      :error -> :error
      {:ok, response} ->
        send(callback, {:message, Message.parse response})
      err ->
        Logger.error("Unexpected error", [err])
    end
    start(socket, callback)
  end
end