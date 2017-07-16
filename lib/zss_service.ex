defmodule ZssService do
  use Application
  alias ZssService.Configuration.{Config, Handler}
  alias ZssService.ServicesSupervisor

  @moduledoc """
  The core ZSSService interface.
  This interface allows consumers to create clients.
  """

  @doc """
  Starts the application. Not for public use.
  """
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(ZssService.ServicesSupervisor, [])
    ]

    opts = [strategy: :one_for_one, name: ZssService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Create an instance of a ZSS Worker Service, configured by the provided parameters.
  Note that this does not create a process yet, it merely provides the required configurations.

  ## Example

  iex> config = ZssService.get_instance(%{sid: "FOO"})
  %ZssService.Configuration.Config{sid: "FOO", heartbeat: 1000, broker: "tcp://127.0.0.1:7776"}
  """
  def get_instance(%{sid: sid} = config) when is_map(config) do
    optional_config = Map.drop(config, [:sid])
    Config.new(sid, optional_config)
  end

  @doc """
  Add a verb to a configuration.
  A verb is a handler associated with a 'verb' (such as GET, CREATE).
  When the service is called by this verb, the handler will be executed.

  These verbs are used to let the service handle messages.
  When starting the service instance, these handlers will be mounted.

  ## Example

  iex> config = ZssService.get_instance(%{sid: "FOO"})
  iex> %{handlers: handlers} = ZssService.add_verb(config, {"get", ZssService.Mocks.TestSender, :send_me})
  iex> handler = Map.get(handlers, "GET")
  iex> is_function(handler)
  true
  """
  def add_verb(%Config{} = configuration, {verb, module, fun}) do
    handlers = Config.add_handler(configuration, verb, {module, fun})
  end

  @doc """
  Starts an actual worker based on the provided configuration (created with get_instance / add_handler).
  The worker is supervised in its own supervisor, which in turn is hooked to the ZSSService main supervisor.

  returns {:ok, pid}
  """
  def run(%Config{} = configuration) do
    {:ok, pid} = ServicesSupervisor.start_child(configuration)

    service_pid = for {ZssService.Service, process, _, _} <- Supervisor.which_children(pid) do
      process
    end
    |> List.first

    {:ok, service_pid}
  end
end
