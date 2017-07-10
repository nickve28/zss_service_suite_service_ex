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
  def new_socket(%{linger: linger, type: type, identity: identity}) do
    {:ok, socket} = :chumak.socket(:dealer, identity |> String.to_charlist)
    socket
  end

  @doc """
  Links the socket to the C Port to get messages
  """

  @doc """
  Set identity and connect socket to the server
  """
  def connect(socket, identity, server) do
    ["tcp", broker, port] = String.split(server, ":")
    {:ok, _peer_pid} = :chumak.connect(socket, :tcp, '127.0.0.1', 7776)
  end

  @doc """
  Send a message to the server
  """
  def send(socket, message) do
    :chumak.send_multipart(socket, message)
  end

  def receive(socket) do
    :chumak.recv_multipart(socket)
  end

  @doc """
  Cleanup resources: Poller and socket
  """
  def cleanup(socket) do
    :chumak.stop(socket)
    :ok
  end
end
