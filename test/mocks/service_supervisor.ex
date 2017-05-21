defmodule ZssService.Mocks.ServiceSupervisor do
  @moduledoc false

  use GenServer

  def start do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_), do: {:ok, :disabled}

  def enable do
    GenServer.call(__MODULE__, :enable)
  end

  def disable do
    GenServer.call(__MODULE__, :disable)
  end

  def stop(pid) do
    GenServer.call(__MODULE__, {:stop, pid})
  end

  def start_child(sup, {module, fun, args}) do
    GenServer.call(__MODULE__, {:start_child, {sup, {module, fun, args}}})
  end

  def handle_call(:enable, _from, _), do: {:reply, :ok, :enabled}
  def handle_call(:disable, _from, _), do: {:reply, :ok, :disabled}

  def handle_call({:stop, _pid}, _from, :enabled), do: {:reply, :ok, :enabled}
  def handle_call({:start_child, {_sup, {_module, _fun, _args}}}, _from, :enabled) do
    {:reply, :ok, :enabled}
  end

  def handle_call({:start_child, {sup, {module, fun, args}}}, _from, :disabled) do
    res = ZssService.ServiceSupervisor.start_child(sup, {module, fun, args})
    {:reply, res, :disabled}
  end

  def handle_call({:stop, pid}, _from, :disabled) do
    res = ZssService.ServiceSupervisor.stop(pid)
    {:reply, res, :disabled}
  end
end
