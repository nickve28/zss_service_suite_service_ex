defmodule ZssService.Adapters.Socket do
  import ZssService.Adapters.Sender
  @moduledoc """
  Provides a readable interface that hides away the functions used by the czmq library.

  This in turn allows a clear test mock to be made a well.
  """

  @doc """
  Creates a new socket, with the provided argument map

  Map arguments:\n
  - linger: How long messages should be retained after the socket is closed\n
  - type: The socket type. eg: :dealer, :router\n

  Returns: Socket
  """
  def new_socket(%{linger: linger, type: type}) do
    {:ok, ctx} = :czmq.start_link

    :czmq.zctx_set_linger(ctx, linger)
    :czmq.zsocket_new(ctx, type)
  end

  @doc """
  Links the socket to the C Port to get messages
  """
  def link_to_poller(socket) do
    :czmq.subscribe_link(socket, [poll_interval: 50])
  end

  @doc """
  Set identity and connect socket to the server
  """
  def connect(socket, identity, server) do
    :ok = :czmq.zsocket_set_identity(socket, identity)
    :ok = :czmq.zsocket_connect(socket, server)
  end

  @doc """
  Send a message to the server
  """
  def send(socket, message) do
    :czmq.zsocket_send_all(socket, message)
  end

  @doc """
  Cleanup resources: Poller and socket
  """
  def cleanup(socket, poller) do
    :czmq.zsocket_destroy(socket)
    :czmq.unsubscribe(poller)

    :ok
  end
end
