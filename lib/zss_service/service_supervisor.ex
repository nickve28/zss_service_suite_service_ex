defmodule ZssService.ServiceSupervisor do
  import Supervisor.Spec
  @moduledoc """
  A supervisor intended to supervise the Service Workers and their Heartbeat module.
  The Service worker should be added separately, or use the `ZssService` to handle this for you.
  """

  @doc """
  Starts the supervisor
  """
  def start_link(config) do
    import Supervisor.Spec, warn: false

    children = [
    ]

    opts = [strategy: :one_for_all]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Starts a ZSS Worker instance with the given config, supervised by the ServiceSupervisor
  """
  def start_child(pid, {module, fun, args}) do
    Supervisor.start_child(pid, worker(module, args, [function: fun]))
  end
end