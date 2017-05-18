defmodule ZssService.Address do
  @moduledoc """
  A struct containing all logic on how the ZSS Address Frame should be constructed.
  """

  defstruct [
    sid: nil,
    sversion: nil,
    verb: nil
  ]

  @doc """
  Constructs a ZSS Address Frame.
  """
  def new(%{"sid" => sid, "verb" => verb, "sversion" => sversion}) do
    %ZssService.Address{
      sid: sid, verb: verb, sversion: sversion
    }
  end

  def new(%{sid: sid, verb: verb, sversion: sversion}) do
    %ZssService.Address{
      sid: sid, verb: verb, sversion: sversion
    }
  end
end

defmodule ZssService.Message do
  @moduledoc """
  A struct containing all logic on how the ZSS Frames should be constructed.
  """

  import Msgpax

  defstruct [
    identity: nil,
    protocol: "ZSS:0.0",
    type: "REQ",
    rid: nil,
    address: %ZssService.Address{},
    headers: nil,
    status: "",
    payload: nil
  ]

  @doc """
  Creates a new ZssService.Message, with the specified sid, verb and sversion (or default = *)
  Please use this to ensure proper message construction.

  Args:

  - sid: The service identity to route to\n
  - verb: The verb to which should be called\n
  - sversion: The version to use. Default to *
  """
  def new(sid, verb, sversion \\ "*") do
    %ZssService.Message{
      address: ZssService.Address.new(%{
        sid: sid,
        sversion: sversion,
        verb: verb
      }),
      rid: UUID.uuid1()
    }
  end

  @doc """
  Serializes a message to Frames, intended to be sent over via ZeroMQ

  Args:

  - message: A ZssService.Message
  """
  def to_frames(message) do
    [
      message.identity || '',
      message.protocol,
      message.type,
      message.rid,
      pack!(Map.from_struct(message.address)),
      pack!(message.headers),
      message.status,
      pack!(message.payload)
    ]
  end

  @doc """
  Parses Frames to a ZssService.Message. Used to deserialize messages.

  args:

  - frames: Array of frames with or without identity. (7 or 8 length)
  """
  def parse([protocol, type, rid, encoded_address, encoded_headers, status, encoded_payload]) do
    parse(["", protocol, type, rid, encoded_address, encoded_headers, status, encoded_payload])
  end

  def parse([identity, protocol, type, rid, encoded_address, encoded_headers, status, encoded_payload]) do
    %ZssService.Message{
      identity: identity,
      protocol: protocol,
      type: type,
      rid: rid,
      address: ZssService.Address.new(unpack!(encoded_address)),
      headers: unpack!(encoded_headers),
      status: status,
      payload: unpack!(encoded_payload)
    }
  end
end