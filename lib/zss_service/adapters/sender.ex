defmodule ZssService.Adapters.Sender do
  @moduledoc """
  Behavior for data sending, used for contract
  """

  @callback new_socket(%{type: atom(), linger: Integer}) :: pid()
  @callback connect(pid(), String.t, String.t) :: :ok
  @callback send(pid(), ZssService.Message) :: :ok
  @callback cleanup(pid(), pid()) :: :ok
end
