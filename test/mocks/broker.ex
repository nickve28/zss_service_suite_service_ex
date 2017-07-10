defmodule ZssService.Mocks.Broker do
  @moduledoc """
  A mock for testing the full zmq flow
  """

  def get_instance(%{address: address}) do
    {:ok, socket} = :chumak.socket(:router)
    {:ok, _peer} = :chumak.bind(socket, :tcp, 'localhost', 7776)
    {:ok, socket}
  end

  def receive(broker) do
    {:ok, msg} = :chumak.recv_multipart(broker)
    [_identity | message] = msg
    message
  end

  def receive(broker, type) do
    response = ZssService.Mocks.Broker.receive(broker)

    case response  do
      [_, _, type_res | _] = msg when type_res == type -> msg
      _ -> ZssService.Mocks.Broker.receive(broker, type)
    end
  end

  def send(broker, [identity | _] = frames) do
    payload = [identity | frames]
    :ok = :chumak.send_multipart(broker, payload)
  end

  def cleanup(router) do
    :chumak.stop(router)
    #:czmq.zsocket_destroy(router)
  end
end
