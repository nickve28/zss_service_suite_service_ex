defmodule ZssService.Mocks.TestSender do
  @moduledoc false

  def send_me(payload, message) do
    send(self(), {:ok, {payload, message}})
  end

  def send_accepted(payload, message) do
    send(self(), {:ok, {payload, Map.put(message, :status, "202")}})
  end

  def send_bad_request(_payload, message) do
    error = Map.get(Application.get_env(:zss_service, :errors), "400")
    send(self(), {:error, {error, Map.put(message, :status, "400")}})
  end

  def send_invalid_status(_payload, message) do
    send(self(), {:ok, {nil, Map.put(message, :status, "500")}})
  end

  def send_no_content(_payload, message) do
    send(self(), {:ok, {nil, message}})
  end

  def send_unknown_error(_payload, message) do
    send(self(), {:error, {"unknown", Map.put(message, :status, "11800")}})
  end

  def ping(_payload, message) do
    {:ok, {"PONG", Map.put(message, :status, "202")}}
  end
end
