defmodule ZssService.Mocks.DateTime do
  @moduledoc false
  use GenServer

  defmodule State do
    defstruct [
      state: :disabled,
      time: DateTime.utc_now()
    ]
  end

  def start do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_), do: {:ok, %State{}}

  def enable do
    GenServer.call(__MODULE__, :enable)
  end

  def disable do
    GenServer.call(__MODULE__, :disable)
  end

  def stub(verb, response) when is_atom(verb) do
    GenServer.call(__MODULE__, {:stub, verb, response})
  end

  def restore(verb) do
    GenServer.call(__MODULE__, {:restore, verb})
  end

  #Simulate functions
  def utc_now, do: GenServer.call(__MODULE__, :utc_now)

  def handle_call({:stub, verb, response}, _from, %State{} = state) do
    new_state = Map.put(state, verb, response)
    {:reply, :ok, new_state}
  end

  def handle_call({:restore, verb}, _from, %State{} = state) do
    new_state = Map.put(state, verb, nil)
    {:reply, :ok, new_state}
  end

  def handle_call(:enable, _from, state) do
    new_state = %State{state | state: :enabled}
    {:reply, :ok, new_state}
  end

  def handle_call(:disable, _from, state) do
    new_state = %State{state | state: :disabled}
    {:reply, :ok, new_state}
  end

  def handle_call(verb, _from, %{state: :enabled} = state) do
    response = Map.get(state, verb)
    {:reply, response, state}
  end

  def handle_call(verb, _from, %{state: :disabled} = state) do
    response = apply(DateTime, verb, [])
    {:reply, response, state}
  end
end
