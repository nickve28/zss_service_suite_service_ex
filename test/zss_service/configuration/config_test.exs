defmodule ZssService.Configuration.ConfigTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias ZssService.Configuration.Config
  doctest Config

  describe "when making a new worker configuration" do
    test "should make sid uppercase" do
      assert %{sid: "PING"} = Config.new("ping")
    end

    test "should default to heartbeat 1000 if nothing is specified" do
       %{heartbeat: 1000} = Config.new("ping")
    end

    test "should allow custom heartbeat" do
      assert %{heartbeat: 1500} = Config.new("PING", %{heartbeat: 1500})
    end

    test "should default to broker tcp://127.0.0.1:7776 if nothing is specified" do
      assert %{broker: "tcp://127.0.0.1:7776"} = Config.new("PING")
    end

    test "should allow custom broker address" do
      assert %{broker: "tcp://192.168.0.1:7776"} = Config.new("PING", %{broker: "tcp://192.168.0.1:7776"})
    end
  end

  describe "when adding a verb with a non existent handler" do
    test "an error should be returned" do
      config = "ping"
      |> Config.new

      handler = {ZssService.Mocks.TestSender, :non_existing}

      assert {:error, "The function Elixir.ZssService.Mocks.TestSender => non_existing with arity 2 was not found"}
        === Config.add_handler(config, "get", handler)
    end
  end

  describe "when adding a verb" do
    test "should make the verb uppercase" do
      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_me})

      assert %{handlers: %{"GET" => _fun}} = config
    end

    test "calling the handler should send payload" do
      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_me})

      %{handlers: %{"GET" => fun}} = config

      payload = %{"id" => 1}
      headers = %{"X-REQUEST-ID" => "123"}

      fun.(payload, headers)
      receive do
        message ->
          assert {:ok, ^payload} = message
      after 2000 ->
        raise "Timeout, no message received!"
      end
    end
  end
end
