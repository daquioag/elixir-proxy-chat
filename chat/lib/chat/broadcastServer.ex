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

  def nick(pid, name) do
    GenServer.call(@name, {:nick, pid, name})
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
    :ets.insert(@tab, {-1, "testname"})
    everything = :ets.tab2list(@tab)
    IO.inspect(everything)
    {:reply, {:ok, everything}, state}
  end

  @impl true
  def handle_call({:nick, pid, name}, _from, state) do
    # Handle list command
    user = :ets.lookup(@tab, pid)
    if user == [{pid, name}] do
      {:reply, {:ok, "You are already have the name: #{name}"}, state}
    else

      names = get_names()
      IO.inspect(names)
      found = Enum.find(names, &(&1 == name))
      if found == nil do
        :ets.insert(@tab, {pid, name})
        {:reply, {:ok, "You are now have the name: #{name}"}, state}
      else
      {:reply,  {:error, "The name: #{name} is already taken"}, state}
      end
    end
  end

  @impl true
  def handle_call({:bc, message}, from, state) do
    current_user = :ets.lookup(@tab, from)
    if current_user == [] do
      {:reply, {:error, "need to make a nickname first"}, state}
    else
      [{_, name}] = current_user
      ets_table = :ets.tab2list(@tab)
      keys = Enum.map(ets_table, &elem(&1, 0))  # Extract the second element from each tuple
      IO.inspect(keys)
      for key <- keys do
        if key != from do
        send(key, "message from #{name}: #{message}")
        end
      end
      {:reply, {:ok, "message successfully broadcased to other clients! "}, state}
    end
  end

  @impl true
  def handle_call(:value, _from, value) do
    {:reply, value, value}
  end

  # @impl true
  # def terminate(_reason, state) do
  #   :ets.insert(@tab, state)
  # end

  defp get_names() do
      pid_dictionary = :ets.tab2list(@tab)

     Enum.map(pid_dictionary, &elem(&1, 1))
  end


end
