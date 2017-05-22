defmodule ZssService.ServiceSupervisor do
  use Supervisor
  alias ZssService.Configuration.Config
  require Logger

  @moduledoc """
  A supervisor intended to supervise the Service Workers and their Heartbeat module.
  The Service worker should be added separately, or use the `ZssService` to handle this for you.
  """

  @doc """
  Starts the supervisor
  """
  def start_link(%Config{} = config) do
    Supervisor.start_link(__MODULE__, config, [])
  end

  def init(config) do
    children = [
      worker(ZssService.Service, [config])
    ]

    opts = [strategy: :rest_for_one]
    Logger.debug(fn -> "Service supervisor started with #{inspect self}" end)
    supervise(children, opts)
  end

  @doc """
  Starts an instance with the given config, supervised by the ServiceSupervisor
  """
  def start_child(sup, {module, fun, args}) do
    Logger.debug(fn -> "Supervisor #{inspect sup} starting process for Heartbeat, called from #{inspect self()}" end)
    {:ok, pid} = Supervisor.start_child(sup, worker(module, args, [function: fun]))
  end

  def stop(pid, reason \\ :normal) do
    Supervisor.stop(pid, reason)
  end
end
