defmodule ZssService.ServiceSupervisor do
  use Supervisor

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

  def start_child(config) do
    Supervisor.start_child(__MODULE__, [config])
  end

end