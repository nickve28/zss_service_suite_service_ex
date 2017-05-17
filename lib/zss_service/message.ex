defmodule ZssService.Message do
  import Msgpax

  defstruct [
    identity: nil,
    protocol: "ZSS:0.0",
    type: "REQ",
    rid: UUID.uuid1(),
    address: %{},
    headers: nil,
    status: nil,
    payload: nil
  ]

  def new(sid, verb, sversion \\ "*") do
    %ZssService.Message{
      address: %{
        sid: sid,
        sversion: sversion,
        verb: verb
      }
    }
  end

  def to_frames(message) do
    [
      message.identity || "",
      message.protocol,
      message.type,
      message.rid,
      pack!(message.address),
      pack!(message.headers),
      pack!(message.status),
      pack!(message.payload)
    ]
  end
end