defmodule ZssService.Address do
  defstruct [
    sid: nil,
    sversion: nil,
    verb: nil
  ]

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

  def to_frames(message) do
    [
      message.identity || '',
      message.protocol,
      message.type,
      message.rid,
      pack!(Map.from_struct(message.address)),
      pack!(message.headers),
      message.status, #nodejs client crashes on this because it apparently becomes null
      pack!(message.payload)
    ]
  end

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

  def to_s(%ZssService.Message{type: type} = _msg) do
    type
  end
end