defmodule ZssService do
  use Application
  alias ZssService.Configuration.{Config, Handler}
  alias ZssService.ServicesSupervisor

  @moduledoc """
  Documentation for ZssService.
  """

  @doc """
    Starts the application
  """
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(ZssService.ServicesSupervisor, [])
    ]

    opts = [strategy: :one_for_one, name: User.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def get_instance(%{sid: sid} = config) when is_map(config) do
    optional_config = Map.drop(config, [:sid])
    Config.new(sid, optional_config)
  end

  def add_verb(%Config{} = configuration, {verb, module, fun}) do
    handlers = Config.add_handler(configuration, verb, {module, fun})
  end

  def run(%Config{} = configuration) do
    {:ok, pid} = ServicesSupervisor.start_child(configuration)

    service_pid = for {ZssService.Service, process, _, _} <- Supervisor.which_children(pid) do
      process
    end
    |> List.first

    {:ok, service_pid}
  end
end
