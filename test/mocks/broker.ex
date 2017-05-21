defmodule ZssService.Mocks.Broker do
  @moduledoc """
  A mock for testing the full zmq flow
  """

  def get_instance(%{address: address}) do
    {:ok, context} = :czmq.start_link

    broker = :czmq.zsocket_new(context, :router)
    {:ok, _port} = :czmq.zsocket_bind(broker, address)

    {:ok, broker}
  end

  def receive(broker) do
    :timer.sleep(50)
    case :czmq.zframe_recv_all(broker) do
      :error -> :error
      {:ok, [_identity | message]} -> message
    end
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
    :ok = :czmq.zsocket_send_all(broker, payload)
  end
end
