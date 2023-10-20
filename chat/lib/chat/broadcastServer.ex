defmodule Chat.BroadcastServer do
  use GenServer
  @name {:global, __MODULE__}
  @tab Chat.BroadcastServer.Table

  def start_link(_args) do
    IO.puts("Starting BroadCastServer!")
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  # for testing purposes we use the pid and from
  def handle_call(:list, _from, state) do
    {:reply, {:ok, get_names()}, state}
  end

  @impl true
  def handle_call({:nick, pid, name}, _from, state) do
    user = :ets.lookup(@tab, pid)
    if user == [{pid, name}] do
      {:reply, {:ok, "You already have the nickname: '#{name}'"}, state}
    else
      if !Enum.member?(get_names(), name) do # !Enum.member?(get_names(), name) this checks if name is a member of get_names()
        :ets.insert(@tab, {pid, name}) # so if name is not in get_names(), we add the name and pid to the ETS table.
        {:reply, {:ok, "You now have the nickname: '#{name}'"}, state}
      else
        {:reply, {:error, "The nickname: '#{name}' is already taken"}, state}
      end
    end
  end

  @impl true
  def handle_call({:bc, sender_pid}, _from, state) do

    case :ets.lookup(@tab, sender_pid) do
      [] ->
        {:reply, {:error, "You must set a nickname before broadcasting a message."}, state}

      [{_, sender_name}] ->
        keys = get_keys() |> Enum.filter( fn pid -> pid != sender_pid end)
        {:reply, {:ok, keys, sender_name}, state}

    end
  end

  @impl true
  def handle_call({:msg, receiver_name, sender_pid}, _from, state) do
    IO.inspect("receiver_name")
    IO.inspect(receiver_name)

    case :ets.lookup(@tab, sender_pid) do
      [] ->
        {:reply, {:error, "You must set a nickname before broadcasting a message."}, state}

      [{_, sender_name}] ->
      case :ets.tab2list(@tab) |> Enum.find(fn {_, name} -> name == receiver_name end) do
        {receiver_pid, _} ->
          {:reply, {:ok, receiver_pid, sender_name}, state}
        nil ->
          {:reply, {:error, "The name: #{receiver_name} does not exist!"}, state}
      end
    end
  end

  defp get_names() do
    :ets.tab2list(@tab) |> Enum.map(&elem(&1, 1))
  end

  defp get_keys() do
    :ets.tab2list(@tab) |> Enum.map(&elem(&1, 0))
  end
end
