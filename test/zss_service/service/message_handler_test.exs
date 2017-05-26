defmodule ZssService.Service.MessageHandlerTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias ZssService.{Service.MessageHandler, Message, Configuration.Config}
  alias ZssService.Mocks.{DateTime, Adapters.Socket}
  doctest MessageHandler

  setup_all do
    Socket.enable

    on_exit(fn ->
      Socket.disable
    end)
  end

  describe "When a request is sent and successfully handled by the verb" do
    test "should set the response-time in the message headers" do
      this = self()

      Socket.stub(:send, fn pid, frames ->
        send(pid, {:message, frames})
        :ok
      end)

      current_time = DateTime.utc_now()
      DateTime.stub(:utc_now, current_time)

      config = "ping"
      |> Config.new
      |> Config.add_handler("get", {ZssService.Mocks.TestSender, :send_me})

      message = Message.new "PING", "GET"
      message = %Message{message | payload: %{"id" => "1"}}
      message = %Message{message | headers: %{"X-REQUEST-ID" => "123"}}
      message = %Message{message | identity: "SUBSCRIPTION#" <> message.rid}

      MessageHandler.handle_msg(message, this, %{config: config})

      receive do
        {:message, frames} ->
          [_, _, _, _, _, encoded_headers, _, _] = frames
          headers = Msgpax.unpack!(encoded_headers)
          %{"response-time" => time} = headers
          assert is_binary(time) == true
      end
    end
  end
end
