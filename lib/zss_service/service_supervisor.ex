defmodule ZssService.ServiceSupervisor do
  import Supervisor.Spec
  @moduledoc """
  A supervisor intended to supervise the Service Workers.
  """

  @doc """
  Starts the supervisor
  """
  def start_link do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(ZssService.Service, [])
    ]

    opts = [strategy: :simple_one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Starts a ZSS Worker instance with the given config, supervised by the ServiceSupervisor
  """
  def start_child(config) do
    Supervisor.start_child(__MODULE__, [config])
  end
end