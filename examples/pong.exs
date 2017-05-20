defmodule Example.Pong do
  def start do
    config = %{
      sid: "PING_ME"
    }

    {:ok, pid} = ZssService.get_instance config
    ZssService.Service.add_verb(pid, {"get", Examples.SampleHandler, :ping_me})
    ZssService.Service.add_verb(pid, {"list", Examples.SampleHandler, :ping_me_more})

    ZssService.Service.run pid

    loop
  end

  def loop() do #Keep the script running
    loop()
  end
end

defmodule Examples.SampleHandler do
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
