defmodule ZssService.Receiver do
  @moduledoc """
  The receiver of messages for a service worker
  Since we need to wait for a message, but it shouldn't block other operations,
  a separate Task should call this
  """
  require Logger
  alias ZssService.Message

  @doc """
  Starts the message receiver
  This is not a Genserver, and is used in conjunction with Task.Supervisor

  Args:

  - socket: ZMQ Socket\n
  - callback: the module to which the result should be sent. Message will be in the format {:message, payload}\n
  """
  def start(socket, callback) do
    case :czmq.zframe_recv_all(socket) do
      :error -> :error #no data = error sadly, cant do anything about internals of the lib
      {:ok, response} ->
        send(callback, {:message, Message.parse response})
      err ->
        Logger.error("Unexpected error", [err])
    end
    start(socket, callback)
  end
end
