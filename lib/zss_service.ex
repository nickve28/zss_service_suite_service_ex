defmodule ZssService do
  use Application
  @moduledoc """
  Documentation for ZssService.
  """

  @doc """
    Starts the application
  """
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(ZssService.ServiceSupervisor, [])
    ]

    opts = [strategy: :one_for_one, name: User.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def get_instance(config) when is_map(config) do
    ZssService.ServiceSupervisor.start_child(config)
  end
end
