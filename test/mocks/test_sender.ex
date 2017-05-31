defmodule ZssService.Mocks.TestSender do
  @moduledoc false

  def send_me(payload, _message) do
    send(self(), {:ok, payload})
  end

  def send_accepted(payload, message) do
    send(self(), {:ok, payload, 202})
  end

  def send_bad_request(_payload, message) do
    error = Map.get(Application.get_env(:zss_service, :errors), "400")
    send(self(), {:error, error, 400})
  end

  def send_invalid_status(_payload, message) do
    send(self(), {:ok, nil, 500})
  end

  def send_no_content(_payload, message) do
    send(self(), {:ok, nil})
  end

  def send_unknown_error(_payload, message) do
    send(self(), {:error, "unknown", 11_800})
  end

  def ping(_payload, message) do
    {:ok, "PONG", 202}
  end
end
