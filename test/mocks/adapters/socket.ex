defmodule ZssService.Mocks.Adapters.Socket do
  @behaviour ZssService.Adapters.Sender

  use GenServer

  defmodule State do
    defstruct [
      state: :disabled,
      handlers: %{}
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

  #Simulate functions
  def new_socket(config), do: GenServer.call(__MODULE__, {:new_socket, [config]})

  def link_to_poller(socket), do: GenServer.call(__MODULE__, {:link_to_poller, [socket]})

  def connect(socket, identity, server), do: GenServer.call(__MODULE__, {:send, [socket, identity, server]})

  def send(socket, msg), do: GenServer.call(__MODULE__, {:send, [socket, msg]})

  def cleanup(socket, poller), do: GenServer.call(__MODULE__, {:cleanup, [socket, poller]})

  def handle_call({:stub, verb, response}, _from, %State{handlers: handlers} = state) do
    handlers = Map.put(handlers, verb, response)
    {:reply, :ok, %State{state | handlers: handlers}}
  end

  def handle_call(:enable, _from, state) do
    new_state = %State{state | state: :enabled}
    {:reply, :ok, new_state}
  end

  def handle_call(:disable, _from, state) do
    new_state = %State{state | state: :disabled}
    {:reply, :ok, new_state}
  end

  def handle_call({verb, _args}, _from, %{state: :enabled, handlers: handlers} = state) do
    response = Map.get(handlers, verb, :ok) #default to :ok
    {:reply, response, state}
  end

  def handle_call({fun_name, args}, _from, %{state: :disabled} = state) do
    response = apply(ZssService.Adapters.Socket, args)
    {:reply, response, state}
  end
end