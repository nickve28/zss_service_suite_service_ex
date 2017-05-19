defmodule ZssService.MessageTest do
  use ExUnit.Case

  alias ZssService.{Message, Address}
  doctest Message
  doctest Address

  describe "when converting to frames (to_frames)" do
    test "should encode Integer payload" do
      message = Message.new "SUBSCRIPTION", "CREATE"
      message = %Message{message | payload: 1}

      [payload | _] = message
      |> Message.to_frames
      |> Enum.reverse

      assert Msgpax.unpack!(payload) === 1
    end

    test "should encode Boolean true payload" do
      message = Message.new "SUBSCRIPTION", "CREATE"
      message = %Message{message | payload: true}

      [payload | _] = message
      |> Message.to_frames
      |> Enum.reverse

      assert Msgpax.unpack!(payload) === true
    end

    test "should encode Boolean false payload" do
      message = Message.new "SUBSCRIPTION", "CREATE"
      message = %Message{message | payload: false}

      [payload | _] = message
      |> Message.to_frames
      |> Enum.reverse

      assert Msgpax.unpack!(payload) === false
    end

    test "should encode nil payload" do
      message = Message.new "SUBSCRIPTION", "CREATE"
      message = %Message{message | payload: nil}

      [payload | _] = message
      |> Message.to_frames
      |> Enum.reverse

      assert Msgpax.unpack!(payload) === nil
    end

    test "should encode Float payload" do
      message = Message.new "SUBSCRIPTION", "CREATE"
      message = %Message{message | payload: 1.5}

      [payload | _] = message
      |> Message.to_frames
      |> Enum.reverse

      assert Msgpax.unpack!(payload) === 1.5
    end

    test "should encode String payload" do
      message = Message.new "SUBSCRIPTION", "CREATE"
      message = %Message{message | payload: "String"}

      [payload | _] = message
      |> Message.to_frames
      |> Enum.reverse

      assert Msgpax.unpack!(payload) === "String"
    end

    test "should encode Charlist payload" do
      message = Message.new "SUBSCRIPTION", "CREATE"
      message = %Message{message | payload: 'Charlist'}

      [payload | _] = message
      |> Message.to_frames
      |> Enum.reverse

      assert Msgpax.unpack!(payload) === 'Charlist'
    end

    test "should encode Array payload" do
      message = Message.new "SUBSCRIPTION", "CREATE"
      message = %Message{message | payload: [1, 2]}

      [payload | _] = message
      |> Message.to_frames
      |> Enum.reverse

      assert Msgpax.unpack!(payload) === [1, 2]
    end

    test "should encode Map payload" do
      message = Message.new "SUBSCRIPTION", "CREATE"
      message = %Message{message | payload: %{a: [1, "b"]}}

      [payload | _] = message
      |> Message.to_frames
      |> Enum.reverse

      assert Msgpax.unpack!(payload) ===  %{"a" => [1, "b"]}
    end
  end

  describe "when converting frames to a message" do
    test "should decode Integer payload" do
      encoded_address = %{sid: "SUBSCRIPTION", verb: "CREATE", sversion: "*"} |> Msgpax.pack!
      encoded_headers = %{"headers" => %{"X-REQUEST-ID" => "123"}} |> Msgpax.pack!
      encoded_payload = 1 |> Msgpax.pack!


      result = ["ZSS:0.0", "REP", "123", encoded_address, encoded_headers, "200", encoded_payload]
      |> Message.parse

      assert %Message{payload: 1} = result
    end

    test "should decode Boolean true payload" do
      encoded_address = %{sid: "SUBSCRIPTION", verb: "CREATE", sversion: "*"} |> Msgpax.pack!
      encoded_headers = %{"headers" => %{"X-REQUEST-ID" => "123"}} |> Msgpax.pack!
      encoded_payload = true |> Msgpax.pack!


      result = ["ZSS:0.0", "REP", "123", encoded_address, encoded_headers, "200", encoded_payload]
      |> Message.parse

      assert %Message{payload: true} = result
    end

    test "should decode Boolean false payload" do
      encoded_address = %{sid: "SUBSCRIPTION", verb: "CREATE", sversion: "*"} |> Msgpax.pack!
      encoded_headers = %{"headers" => %{"X-REQUEST-ID" => "123"}} |> Msgpax.pack!
      encoded_payload = false |> Msgpax.pack!


      result = ["ZSS:0.0", "REP", "123", encoded_address, encoded_headers, "200", encoded_payload]
      |> Message.parse

      assert %Message{payload: false} = result
    end

    test "should decode nil payload" do
      encoded_address = %{sid: "SUBSCRIPTION", verb: "CREATE", sversion: "*"} |> Msgpax.pack!
      encoded_headers = %{"headers" => %{"X-REQUEST-ID" => "123"}} |> Msgpax.pack!
      encoded_payload = nil |> Msgpax.pack!


      result = ["ZSS:0.0", "REP", "123", encoded_address, encoded_headers, "200", encoded_payload]
      |> Message.parse

      assert %Message{payload: nil} = result
    end

    test "should decode Float payload" do
      encoded_address = %{sid: "SUBSCRIPTION", verb: "CREATE", sversion: "*"} |> Msgpax.pack!
      encoded_headers = %{"headers" => %{"X-REQUEST-ID" => "123"}} |> Msgpax.pack!
      encoded_payload = 1.5 |> Msgpax.pack!


      result = ["ZSS:0.0", "REP", "123", encoded_address, encoded_headers, "200", encoded_payload]
      |> Message.parse

      assert %Message{payload: 1.5} = result
    end

    test "should decode String payload" do
      encoded_address = %{sid: "SUBSCRIPTION", verb: "CREATE", sversion: "*"} |> Msgpax.pack!
      encoded_headers = %{"headers" => %{"X-REQUEST-ID" => "123"}} |> Msgpax.pack!
      encoded_payload = "String" |> Msgpax.pack!


      result = ["ZSS:0.0", "REP", "123", encoded_address, encoded_headers, "200", encoded_payload]
      |> Message.parse

      assert %Message{payload: "String"} = result
    end

    test "should decode Array payload" do
      encoded_address = %{sid: "SUBSCRIPTION", verb: "CREATE", sversion: "*"} |> Msgpax.pack!
      encoded_headers = %{"headers" => %{"X-REQUEST-ID" => "123"}} |> Msgpax.pack!
      encoded_payload = [1, 2] |> Msgpax.pack!


      result = ["ZSS:0.0", "REP", "123", encoded_address, encoded_headers, "200", encoded_payload]
      |> Message.parse

      assert %Message{payload: [1, 2]} = result
    end

    test "should decode Map payload" do
      encoded_address = %{sid: "SUBSCRIPTION", verb: "CREATE", sversion: "*"} |> Msgpax.pack!
      encoded_headers = %{"headers" => %{"X-REQUEST-ID" => "123"}} |> Msgpax.pack!
      encoded_payload = %{"a" => [1, "b"]} |> Msgpax.pack!


      result = ["ZSS:0.0", "REP", "123", encoded_address, encoded_headers, "200", encoded_payload]
      |> Message.parse

      assert %Message{payload: %{"a" => [1, "b"]}} = result
    end
  end
end