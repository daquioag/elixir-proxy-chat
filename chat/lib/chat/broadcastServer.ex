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

  def bc2(msg) do
    GenServer.call(@name, {:bc2, msg})
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
  # for testing purposes we use the pid and from
  def handle_call(:list, _from, state) do
    # Handle list command
    {:reply, {:ok, get_names()}, state}
  end

  @impl true
  def handle_call({:nick, pid, name}, _from, state) do
    # Handle list command
    IO.inspect("    # Handle list command    ")
    user = :ets.lookup(@tab, pid)

    if user == [{pid, name}] do
      {:reply, {:ok, "You already have the nickname: '#{name}'"}, state}
    else
      names = get_names()
      IO.inspect(names)
      found = Enum.find(names, &(&1 == name))

      if found == nil do
        :ets.insert(@tab, {pid, name})
        {:reply, {:ok, "You now have the nickname: '#{name}'"}, state}
      else
        {:reply, {:error, "The nickname: '#{name}' is already taken"}, state}
      end
    end
  end

  @impl true
  def handle_call({:bc, message}, from, state) do
    IO.inspect("from")
    {pid, _} = from
    current_user = :ets.lookup(@tab, pid)

    if current_user == [] do
      {:reply, {:error, "need to make a nickname first"}, state}
    else
      [{_, name}] = current_user
      keys = get_keys()
      IO.inspect(keys)

      for key <- keys do
        if key != pid do
          IO.inspect("sending message to:")
          IO.inspect(key)
          send(key, {:message, "Message from #{name}: #{message}"})
        end
      end

      {:reply, {:ok, "message successfully broadcased to other clients! "}, state}
    end
  end

  @impl true
  def handle_call({:bc2, message}, from, state) do
    current_user = :ets.lookup(@tab, from)

    if current_user == [] do
      {:reply, {:error, "need to make a nickname first"}, state}
    else
      keys = get_keys()
      {:reply, {:ok, keys}, state}
    end
  end

  @impl true
  def handle_call({:msg, receiver_name, message}, from, state) do
    {sender_pid, _} = from
    current_user = :ets.lookup(@tab, sender_pid)

    if current_user == [] do
      {:reply, {:error, "You need to register a nickname first!"}, state}
    else
      case :ets.lookup(@tab, receiver_name) do
        [{receiver_pid, _}] ->
          {:reply, {:ok, receiver_pid}, state}

        _ ->
          {:reply, {:error, "The name: #{receiver_name} does not exist!"}, state}
      end
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

  defp get_keys() do
    pid_dictionary = :ets.tab2list(@tab)
    Enum.map(pid_dictionary, &elem(&1, 0))
  end

  defp check_name(name) do
    names = get_names()
    IO.inspect(names)
    Enum.find(names, &(&1 == name))
  end
end
