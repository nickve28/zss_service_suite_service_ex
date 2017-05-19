defmodule ZssService.ServiceTest do
  use ExUnit.Case

  alias ZssService.Service
  alias ZssService.Mocks.Adapters.Socket
  doctest Service

  setup_all do
    Socket.enable

    on_exit(fn -> Socket.disable end)
  end

  describe "when making a new worker" do
    test "should make sid uppercase" do
      config = %{sid: "ping"}

      {:ok, pid} = Service.start_link(config)
      assert %{config: %{sid: "PING"}} = :sys.get_state(pid)
    end

    test "should default to heartbeat 1000 if nothing is specified" do
      config = %{sid: "PING"}

      {:ok, pid} = Service.start_link(config)
      assert %{config: %{heartbeat: 1000}} = :sys.get_state(pid)
    end

    test "should allow custom heartbeat" do
      config = %{sid: "PING", heartbeat: 1500}

      {:ok, pid} = Service.start_link(config)
      assert %{config: %{heartbeat: 1500}} = :sys.get_state(pid)
    end

    test "should default to broker tcp://127.0.0.1:7776 if nothing is specified" do
      config = %{sid: "PING"}

      {:ok, pid} = Service.start_link(config)
      assert %{config: %{broker: "tcp://127.0.0.1:7776"}} = :sys.get_state(pid)
    end

    test "should allow custom broker address" do
      config = %{sid: "PING", broker: "tcp://192.168.0.1:7776"}

      {:ok, pid} = Service.start_link(config)
      assert %{config: %{broker: "tcp://192.168.0.1:7776"}} = :sys.get_state(pid)
    end

    test "should add identity to the config" do
      config = %{sid: "PING", broker: "tcp://192.168.0.1:7776"}

      {:ok, pid} = Service.start_link(config)
      %{config: %{identity: identity}} = :sys.get_state(pid)
      identity = identity |> String.Chars.to_string
      assert "PING#" <> _foo = identity
    end
  end

  describe "when adding a verb" do
    test "should make the verb uppercase" do
      config = %{sid: "ping"}

      {:ok, pid} = Service.start_link(config)
      assert %{config: %{sid: "PING"}} = :sys.get_state(pid)
    end
  end
end