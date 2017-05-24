defmodule ZssService.Mocks.TestSender do
  @moduledoc false

  def send_me(payload, message) do
    send(self(), {:ok, {payload, message}})
  end

  def send_bad_request(_payload, message) do
    error = Map.get(Application.get_env(:zss_service, :errors), "400")
    send(self(), {:ok, {error, Map.put(message, :status, "400")}})
  end

  def send_unknown_error(_payload, message) do
    send(self(), {:ok, {"unknown", Map.put(message, :status, "11800")}})
  end

  def ping(_payload, message) do
    {:ok, {"PONG", Map.put(message, :status, "202")}}
  end
end
