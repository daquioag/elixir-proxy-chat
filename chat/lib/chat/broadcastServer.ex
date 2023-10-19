defmodule Chat.BroadcastServer do
  use GenServer
  @name {:global, __MODULE__}
  @tab Chat.BroadcastServer.Table

  def start_link(_args) do
    IO.puts("Starting BroadCastServer!")
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  def list() do
    GenServer.call(@name, :list)
  end

  def nick(name) do
    GenServer.call(@name, {:nick, name})
  end

  def bc(msg) do
    GenServer.call(@name, {:bc, msg})
  end

  def msg(name, message) do
    GenServer.call(@name, {:msg, name, message})
  end

  def terminate_user(pid) do
    GenServer.cast(@name, {:terminate_user, pid})
  end

  def value() do
    GenServer.call(@name, :value)
  end

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_call(:list, _from, state) do
    # Handle list command
    :ets.insert(@tab, {:ok, "TESTSETSETSET"})
    everything = :ets.tab2list(@tab)
    IO.inspect(everything)
    {:reply, {:ok, everything}, state}
  end

  @impl true
  def handle_call({:nick, name}, _from, state) do
    # Handle list command
    {:reply, state, state}
  end

  @impl true
  def handle_call(:value, _from, value) do
    {:reply, value, value}
  end

  @impl true
  def terminate(_reason, state) do
    :ets.insert(@tab, state)
  end

end
