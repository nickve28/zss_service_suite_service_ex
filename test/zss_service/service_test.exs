defmodule ZssService.ServiceTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias ZssService.{Service, Message, Configuration.Config}
  alias ZssService.Mocks.{Adapters.Socket, ServiceSupervisor}
  doctest Service

  setup_all do
    Socket.enable
    ServiceSupervisor.enable

    Socket.stub(:link_to_poller, {:ok, spawn(fn -> :ok end)})

    on_exit(fn ->
      Socket.disable
      ServiceSupervisor.disable
    end)
  end

  #some case fails where unit tests run the process, perhaps a non matching stub response somewhere
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

      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_me})

      {:ok, _pid} = Service.start_link(config)
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
      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_me})

      {:ok, _pid} = Service.start_link(config)
    end
  end

  describe "when receiving messages" do
    setup do
      on_exit(fn ->
        Socket.restore(:new_socket)
        Socket.restore(:send)
        Socket.restore(:cleanup)
      end)
    end

    @tag :receive
    test "should handle heartbeat REP messages" do
      Socket.stub(:new_socket, self())

      Socket.stub(:send, fn test_pid, _msg ->
        message = ZssService.Message.new "SMI", "HEARTBEAT"
        message = %ZssService.Message{message | type: "REP"}
        message = %ZssService.Message{message | headers: %{"X-REQUEST-ID" => "123"}}

        send(test_pid, {:poller_stub, message |> Message.to_frames})
        :ok
      end)

      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_me})

      {:ok, _pid} = Service.start_link(config)

      receive do
        {_, message} ->
          assert (message |> Message.parse).address.verb === "HEARTBEAT"
      end
    end

    @tag :receive
    test "should handle UP REP messages" do
      Socket.stub(:new_socket, self())

      Socket.stub(:send, fn test_pid, _msg ->
        message = Message.new "SMI", "UP"
        message = %Message{message | type: "REP"}
        message = %Message{message | headers: %{"X-REQUEST-ID" => "123"}}

        send(test_pid, {:poller_stub, message |> Message.to_frames})
        :ok
      end)

      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_me})

      {:ok, _pid} = Service.start_link(config)

      receive do
        {_, message} ->
          assert (message |> Message.parse).address.verb === "UP"
      after 2000 ->
        raise "Timeout exceeded"
      end
    end

    @tag :receive
    test "should handle matching verbs" do
      Socket.stub(:new_socket, self()) #Send message to this process
      Socket.stub(:send, fn receiver, message ->
        send(receiver, {:message, message})
        :ok
      end)

      message = Message.new "PING", "GET"
      message = %Message{message | payload: %{"id" => "1"}}
      message = %Message{message | headers: %{"X-REQUEST-ID" => "123"}}
      message = %Message{message | identity: "SUBSCRIPTION#" <> message.rid}

      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_me})

      {:ok, instance} = Service.start_link(config)

      send(instance, {:msg, message |> Message.to_frames})

      receive do
        {:message, [_, _, "REP" | _] = message} ->
          assert (message |> Message.parse).address.verb === "GET"
      after 2000 ->
        raise "Timeout exceeded"
      end
    end

    @tag :receive
    test "should allow custom success response codes" do
      Socket.stub(:new_socket, self()) #Send message to this process
      Socket.stub(:send, fn receiver, message ->
        send(receiver, {:message, message})
        :ok
      end)

      message = Message.new "PING", "GET"
      message = %Message{message | payload: %{"id" => "1"}}
      message = %Message{message | headers: %{"X-REQUEST-ID" => "123"}}
      message = %Message{message | identity: "SUBSCRIPTION#" <> message.rid}

      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_accepted})

      {:ok, instance} = Service.start_link(config)

      send(instance, {:msg, message |> Message.to_frames})

      receive do
        {:message, [_, _, "REP" | _] = message} ->
          assert (message |> Message.parse).status === "202"
      after 2000 ->
        raise "Timeout exceeded"
      end
    end

    @tag :receive
    test "should return 500 if a wrong success code is passed in success response" do
      Socket.stub(:new_socket, self()) #Send message to this process
      Socket.stub(:send, fn receiver, message ->
        send(receiver, {:message, message})
        :ok
      end)

      message = Message.new "PING", "GET"
      message = %Message{message | payload: %{"id" => "1"}}
      message = %Message{message | headers: %{"X-REQUEST-ID" => "123"}}
      message = %Message{message | identity: "SUBSCRIPTION#" <> message.rid}

      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_invalid_status})

      {:ok, instance} = Service.start_link(config)

      send(instance, {:msg, message |> Message.to_frames})

      receive do
        {:message, [_, _, "REP" | _] = message} ->
          assert (message |> Message.parse).status === "500"
      after 2000 ->
        raise "Timeout exceeded"
      end
    end

    @tag :receive
    test "should return 204 if no content is returned" do
      Socket.stub(:new_socket, self()) #Send message to this process
      Socket.stub(:send, fn receiver, message ->
        send(receiver, {:message, message})
        :ok
      end)

      message = Message.new "PING", "GET"
      message = %Message{message | payload: %{"id" => "1"}}
      message = %Message{message | headers: %{"X-REQUEST-ID" => "123"}}
      message = %Message{message | identity: "SUBSCRIPTION#" <> message.rid}

      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_no_content})

      {:ok, instance} = Service.start_link(config)

      send(instance, {:msg, message |> Message.to_frames})

      receive do
        {:message, [_, _, "REP" | _] = message} ->
          assert (message |> Message.parse).status === "204"
      after 2000 ->
        raise "Timeout exceeded"
      end
    end

    @tag :receive
    test "should coerce 400 errors into status 400" do
      Socket.stub(:new_socket, self()) #Send message to this process
      Socket.stub(:send, fn receiver, message ->
        send(receiver, {:message, message})
        :ok
      end)

      message = Message.new "PING", "GET"
      message = %Message{message | payload: %{"id" => "1"}}
      message = %Message{message | headers: %{"X-REQUEST-ID" => "123"}}
      message = %Message{message | identity: "SUBSCRIPTION#" <> message.rid}

      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_bad_request})

      {:ok, instance} = Service.start_link(config)

      send(instance, {:msg, message |> Message.to_frames})

      receive do
        {:message, [_, _, "REP" | _] = message} ->
          assert (message |> Message.parse).status === "400"
      after 2000 ->
        raise "Timeout exceeded"
      end
    end

    @tag :receive
    test "should coerce >4xx errors into an error model" do
      Socket.stub(:new_socket, self()) #Send message to this process
      Socket.stub(:send, fn receiver, message ->
        send(receiver, {:message, message})
        :ok
      end)

      message = Message.new "PING", "GET"
      message = %Message{message | payload: %{"id" => "1"}}
      message = %Message{message | headers: %{"X-REQUEST-ID" => "123"}}
      message = %Message{message | identity: "SUBSCRIPTION#" <> message.rid}

      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_bad_request})

      {:ok, instance} = Service.start_link(config)

      send(instance, {:msg, message |> Message.to_frames})

      expected = %{
        "code" => 400,
        "developer_message" => "The request cannot be fulfilled due to bad syntax.",
        "user_message" => "An error occured",
        "validation_errors" => []
      }

      receive do
        {:message, [_, _, "REP" | _] = message} ->
          assert (message |> Message.parse).payload === expected
      after 2000 ->
        raise "Timeout exceeded"
      end
    end


    @tag :receive
    test "should coerce non matching codes to 500" do
      Socket.stub(:new_socket, self()) #Send message to this process
      Socket.stub(:send, fn receiver, message ->
        send(receiver, {:message, message})
        :ok
      end)

      message = Message.new "PING", "GET"
      message = %Message{message | payload: %{"id" => "1"}}
      message = %Message{message | headers: %{"X-REQUEST-ID" => "123"}}
      message = %Message{message | identity: "SUBSCRIPTION#" <> message.rid}

      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_unknown_error})

      {:ok, instance} = Service.start_link(config)

      send(instance, {:msg, message |> Message.to_frames})

      expected = %{
        "developer_message" => "There was an error while processing this request. There is probably something wrong with the API server.",
        "user_message" => "There was an error while processing this request.",
        "code" => 500,
        "validation_errors" => []
      }

      receive do
        {:message, [_, _, "REP" | _] = message} ->
          assert (message |> Message.parse).payload === expected
      after 2000 ->
        raise "Timeout exceeded"
      end
    end
  end
end
