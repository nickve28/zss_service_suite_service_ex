defmodule ZssService.Mocks.TestSender do
  @moduledoc false

  def send_me(payload, message) do
    send(self(), {:test_message, payload, message})
  end

  def ping(_payload, message) do
    {:ok, {"PONG", Map.put(message, :status, "202")}}
  end
end
