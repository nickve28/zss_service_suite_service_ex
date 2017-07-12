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
  def new_socket(%{type: type, identity: identity}) do
    {:ok, socket} = :chumak.socket(type, identity |> String.to_charlist)
    socket
  end

  @doc """
  Connect the socket to the specified server
  """
  def connect(socket, server) do
    "tcp://" <> address_port = server
    [address, port] = String.split(address_port, ":")
    {:ok, _peer_pid} = :chumak.connect(
      socket,
      :tcp,
      address |> String.to_charlist,
      port |> String.to_integer
    )
  end

  @doc """
  Send a message to the server
  """
  def send(socket, message) do
    :chumak.send_multipart(socket, message)
  end

  @doc """
  Receive a message send to the socket
  """
  def receive(socket) do
    :chumak.recv_multipart(socket)
  end

  @doc """
  Cleans up the socket
  """
  def cleanup(socket) do
    :chumak.stop(socket)
    :ok
  end
end
