defmodule Chat.BroadcastServer do
  use GenServer
  @name {:global, __MODULE__}
  @tab Chat.BroadcastServer.Table

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  def list() do
    GenServer.call(@name, :list)
  end

  @impl true
  def init(name) do
    value =
      case :ets.lookup(@tab, name) do
        [{^name, v}] -> v
        _ -> []
      end

    {:ok, {name, value}}
  end

  @impl true
  def handle_call({:list}, _from, state) do
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
