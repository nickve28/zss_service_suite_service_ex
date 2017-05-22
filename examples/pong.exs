defmodule Example.Pong do
  @moduledoc false

  def start do
    config = %{sid: "PING_ME"}
    |> ZssService.get_instance
    |> ZssService.add_verb({"get", Examples.SampleHandler, :ping_me})
    |> ZssService.add_verb({"list", Examples.SampleHandler, :ping_me_more})

    {:ok, pid} = ZssService.run config
    {:ok, pid} = ZssService.run config
    {:ok, pid} = ZssService.run config

    loop()
  end

  def loop do #Keep the script running
    loop()
  end
end

defmodule Examples.SampleHandler do
  @moduledoc false

  def ping_me(_payload, message) do
    {:ok, {
      %{ping: "PONG"},
      Map.merge(message, %{status: "200"})
     }}
  end

  def ping_me_more(_payload, message) do
    %{"userId" => user_id} = message
    {:ok, {
      [%{ping: "PONG", user_id: user_id}, %{ping: "PANG", user_id: user_id}],
      Map.merge(message, %{status: "202"})
     }}
  end
end


Example.Pong.start
