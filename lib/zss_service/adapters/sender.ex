defmodule ZssService.Adapters.Sender do
  @callback new_socket(%{type: atom(), linger: Integer}) :: pid()
  @callback link_to_poller(pid()) :: pid()
  @callback connect(pid(), String.t, String.t) :: :ok
  @callback send(pid(), ZssService.Message) :: :ok
  @callback cleanup(pid(), pid()) :: :ok
end