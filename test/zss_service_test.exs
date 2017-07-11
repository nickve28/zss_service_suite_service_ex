defmodule ZssServiceTest do
  use ExUnit.Case, async: false
  @moduledoc false

  alias ZssService.Mocks.{Broker}
  alias ZssService.{Message}

  doctest ZssService

  #Integration specs
  setup do
    {:ok, broker} = Broker.get_instance(%{address: "tcp://127.0.0.1:7776"})

    {:ok, broker: broker}
  end

  @tag :zmq
  test "Setting up should connect the service to the broker", %{broker: broker} do
    config = %{sid: "FOO1"}

    {:ok, _pid} = config
    |> ZssService.get_instance
    |> ZssService.run

    assert ["FOO" <> _uuid, _, "REQ", _rid, address | _] = Broker.receive(broker)
    assert %{"sid" => "SMI", "verb" => "UP"} = Msgpax.unpack!(address)
  end

  # @tag :zmq
  # test "Setting up should initiate heartbeats and send regularly", %{broker: broker} do
  #   config = %{sid: "FOO2"}

  #   {:ok, _pid} = config
  #   |> ZssService.get_instance
  #   |> ZssService.run

  #   ["FOO" <> _uuid | _] = Broker.receive(broker)
  #   :timer.sleep(1200) #wait for messages
  #   ["FOO" <> _uuid, _, "REQ", _, address | _] = Broker.receive(broker)
  #   assert %{"sid" => "SMI", "verb" => "HEARTBEAT"} = Msgpax.unpack!(address)

  #   :timer.sleep(1200) #wait for messages
  #   ["FOO" <> _uuid, _, "REQ", _, address | _] = Broker.receive(broker)
  #   assert %{"sid" => "SMI", "verb" => "HEARTBEAT"} = Msgpax.unpack!(address)
  # end

  @tag :zmq
  test "Setting up should receive messages and send replies accordingly", %{broker: broker} do
    config = %{sid: "FOO3"}

    config = config
    |> ZssService.get_instance
    |> ZssService.add_verb({"PING", ZssService.Mocks.TestSender, :ping})

    {:ok, instance} = ZssService.run(config)

    ["FOO3" <> _uuid | _] = Broker.receive(broker)

    #TODO find out how to send messages properly from broker.
    #For now, we send the message instead
    message = Message.new("FOO3", "PING")
    message = %Message{message | identity: "SUBSCRIPTION##{UUID.uuid1()}", payload: %{}, headers: %{}}
    frames = message
    |> Message.to_frames

    send(instance, {:ok, frames})

    ["SUBSCRIPTION#" <> _uuid, _, "REP", _, _, _, status, payload] = Broker.receive(broker, "REP")
    assert status === "202"
    assert "PONG" === Msgpax.unpack!(payload)
  end

  #TODO flaky test
  # @tag :down
  # test "Should cleanup when the DOWN command is sent", %{broker: broker} do
  #   config = %{sid: "FOO4"}

  #   config = config
  #   |> ZssService.get_instance

  #   {:ok, instance} = ZssService.run(config)

  #   # ["FOO4" <> _uuid | _] = Broker.receive(broker)

  #   #TODO find out how to send messages properly from broker.
  #   #For now, we send the message instead
  #   frames = Message.new("SMI", "DOWN")
  #   |> Message.to_frames

  #   send(instance, {:ok, frames})

  #   Process.sleep(1500)
  #   assert Process.alive?(instance) === false
  # end
end
