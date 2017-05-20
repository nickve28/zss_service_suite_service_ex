defmodule ZssService.ServicesSupervisor do
  import Supervisor.Spec
  @moduledoc """
  A supervisor intended to supervise the Service Supervisors.
  """

  @doc """
  Starts the supervisor
  """
  def start_link do
    children = [
      supervisor(ZssService.ServiceSupervisor, [])
    ]

    opts = [strategy: :simple_one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Starts a ServiceSupervisor which starts a Worker with the given config
  """
  def start_child(config) do
    Supervisor.start_child(__MODULE__, [config])
  end
end
