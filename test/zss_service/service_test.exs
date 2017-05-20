defmodule ZssService.ServiceTest do
  use ExUnit.Case, async: false

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
      assert Regex.match?(~r/PING#[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/, identity) === true
    end
  end

  describe "when adding a verb" do
    test "should make the verb uppercase" do
      config = %{sid: "ping"}

      {:ok, pid} = Service.start_link(config)
      Service.add_verb(pid, {"get", ZssService.Mocks.TestSender, :send_me})
      assert %{handlers: %{"GET" => _fun}} =:sys.get_state(pid)
    end

    test "calling the handler should send payload" do
      config = %{sid: "ping"}

      {:ok, pid} = Service.start_link(config)
      Service.add_verb(pid, {"get", ZssService.Mocks.TestSender, :send_me})
      %{handlers: %{"GET" => fun}} =:sys.get_state(pid)

      payload = %{"id" => 1}
      headers = %{"X-REQUEST-ID" => "123"}

      fun.(payload, headers)
      receive do
        message ->
          assert {:test_message, ^payload, _} = message
      after 2000 ->
        raise "Timeout, no message received!"
      end
    end

    test "calling the handler should send headers" do
      config = %{sid: "ping"}

      {:ok, pid} = Service.start_link(config)
      Service.add_verb(pid, {"get", ZssService.Mocks.TestSender, :send_me})
      %{handlers: %{"GET" => fun}} =:sys.get_state(pid)

      payload = %{"id" => 1}
      headers = %{"X-REQUEST-ID" => "123"}

      fun.(payload, headers)
      receive do
        message ->
          assert {:test_message, _, ^headers} = message
      after 2000 ->
        raise "Timeout, no message received!"
      end
    end
  end

  describe "when running the worker" do
    setup do
      on_exit(fn ->
        Socket.restore(:connect)
        Socket.restore(:send)
      end)
    end

    @tag :run
    test "should connect to the broker" do
      #Not sure how to improve this yet
      Socket.stub(:connect, fn _socket, identity, broker ->
        assert broker === "tcp://127.0.0.1:7776"
        identity = identity |> String.Chars.to_string
        assert Regex.match?(~r/PING#[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/, identity) === true
        :ok
      end)

      config = %{sid: "ping"}

      {:ok, pid} = Service.start_link(config)
      Service.add_verb(pid, {"get", ZssService.Mocks.TestSender, :send_me})

      :ok = Service.run(pid)
    end

    @tag :run
    test "should register itself to the broker by sending the UP message" do
      #Not sure how to improve this yet
      Socket.stub(:send, fn _socket, msg ->
        [identity, _protocol, type, rid, address, _headers, _status, payload] = msg
        identity = identity |> String.Chars.to_string
        assert Regex.match?(~r/PING#[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/, identity) === true

        assert type === "REQ"
        assert Regex.match?(~r/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/, rid) === true

        decoded_address = Msgpax.unpack!(address)
        assert %{"verb" => "UP", "sid" => "SMI"} = decoded_address

        decoded_payload = Msgpax.unpack!(payload)
        assert "PING" === decoded_payload

        :ok
      end)
      config = %{sid: "ping"}

      {:ok, pid} = Service.start_link(config)
      Service.add_verb(pid, {"get", ZssService.Mocks.TestSender, :send_me})

      :ok = Service.run(pid)
    end
  end

  describe "when receiving messages" do
    setup do
      on_exit(fn ->
        Socket.restore(:new_socket)
        Socket.restore(:send)
      end)
    end

    @tag :receive
    test "should handle heartbeat REP messages" do
      Socket.stub(:new_socket, self)

      Socket.stub(:send, fn test_pid, _msg ->
        message = ZssService.Message.new "SMI", "HEARTBEAT"
        message = %ZssService.Message{message | type: "REP"}
        message = %ZssService.Message{message | headers: %{"X-REQUEST-ID" => "123"}}

        send(test_pid, message)
        :ok
      end)

      config = %{sid: "ping"}

      {:ok, pid} = Service.start_link(config)
      Service.add_verb(pid, {"get", ZssService.Mocks.TestSender, :send_me})

      :ok = Service.run(pid)

      receive do
        message ->
          assert message.address.verb === "HEARTBEAT"
      end
    end

    @tag :receive
    test "should handle UP REP messages" do
      Socket.stub(:new_socket, self)

      Socket.stub(:send, fn test_pid, _msg ->
        message = ZssService.Message.new "SMI", "UP"
        message = %ZssService.Message{message | type: "REP"}
        message = %ZssService.Message{message | headers: %{"X-REQUEST-ID" => "123"}}

        send(test_pid, message)
        :ok
      end)

      config = %{sid: "ping"}

      {:ok, pid} = Service.start_link(config)
      Service.add_verb(pid, {"get", ZssService.Mocks.TestSender, :send_me})

      :ok = Service.run(pid)

      receive do
        message ->
          assert message.address.verb === "UP"
      end
    end

    @tag :receive
    test "should handle matching verbs" do
      Socket.stub(:new_socket, self)

      Socket.stub(:send, fn test_pid, _msg ->
        message = ZssService.Message.new "PING", "GET"
        message = %ZssService.Message{message | payload: %{"id" => "1"}}
        message = %ZssService.Message{message | headers: %{"X-REQUEST-ID" => "123"}}
        message = %ZssService.Message{message | identity: "SUBSCRIPTION#" <> message.rid}

        send(test_pid, message)
        :ok
      end)

      config = %{sid: "ping"}

      {:ok, pid} = Service.start_link(config)
      Service.add_verb(pid, {"get", ZssService.Mocks.TestSender, :send_me})

      :ok = Service.run(pid)

      receive do
        message ->
          assert message.address.verb === "GET"
      end
    end
  end
end