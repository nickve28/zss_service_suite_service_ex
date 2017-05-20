defmodule ZssService.Mocks.TestSender do
  def send_me(payload, message) do
    send(self(), {:test_message, payload, message})
  end
end