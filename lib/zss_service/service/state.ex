defmodule ZssService.Service.State do
  @moduledoc """
  Struct to provide easy navigation through the Service's state, with appropriate defaults
  """

  defstruct [
    config: nil,
    identity: nil,
    socket: nil,
    supervisor: nil
  ]
end
