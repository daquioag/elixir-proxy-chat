defmodule Chat.ProxyServer do
  use GenServer

  def start_link(port \\ 6666) do
    IO.puts("Starting Proxy Server!")
    GenServer.start_link(__MODULE__, port)
  end

  @impl true
  def init(port \\ 6666) do
    opts = [:binary, {:packet, 0}, {:reuseaddr, true}, {:active, :once}]
    {:ok, socket} = :gen_tcp.listen(port, opts)
    spawn(fn -> accept(socket) end)
    {:ok, socket}
  end

  def accept(socket) do
    {:ok, conn} = :gen_tcp.accept(socket)
    spawn(fn -> accept(socket) end)
    IO.puts("#{inspect(self())}: accepted connection #{inspect(conn)}")
    loop(conn)
  end

  defp loop(socket) do
    receive do
      {:tcp, ^socket, data} ->
        IO.inspect("data")
        IO.inspect(data)
        handle_client_command(socket, data)
        :inet.setopts(socket, [{:active, :once}])
        loop(socket)

      {:message, content} ->
        IO.inspect(content)
        :gen_tcp.send(socket, "#{content}\n")
        loop(socket)

      {:tcp_closed, ^socket} ->
        IO.puts("#{inspect(self())}: connection #{inspect(socket)} closed")
        # GenServer.call({:global, Chat.BroadcastServer}, {:delete})
        :gen_tcp.close(socket)

      _ ->
        :ok
        loop(socket)
    end
  end

  def handle_client_command(socket, data) do
    [command | args] = String.split(data, ~r/\s/)

    case command do
      "/LIST" -> handle_list_command(socket)
      "/NICK" -> handle_nick_command(socket, args)
      "/BC" -> handle_bc_command(socket, args)
      "/MSG" -> handle_msg_command(socket, args)
      _ -> handle_unknown_command(socket)
    end
  end

  defp handle_list_command(socket) do
    {:ok, names_list} = GenServer.call({:global, Chat.BroadcastServer}, :list)
    names_string = Enum.join(names_list, ", ")
    :gen_tcp.send(socket, "List of NickNames: ")
    :gen_tcp.send(socket, names_string <> "\n")
  end

  defp handle_nick_command(socket, args) do
    [nickname | _] = args
    case validate_nickname(nickname) do
      true ->
        {_, result} = GenServer.call({:global, Chat.BroadcastServer}, {:nick, self(), nickname})
        :gen_tcp.send(socket, result <> "\n")
      false ->
        :gen_tcp.send(socket, "Invalid Name. Name not added! \n")
    end
end

  defp handle_bc_command(socket, message_list) do
    string_message = Enum.join(message_list, " ")
    if String.trim(string_message) == "" do
      :gen_tcp.send(
        socket,
        "Error: Invalid message! Message cannot be empty.\n"
      )
    else

    case GenServer.call({:global, Chat.BroadcastServer}, {:bc, self()}) do
      {:ok, pid_list, sender_name} ->
        # Handle the case where the call was successful
        for pid <- pid_list do
          send(pid, {:message, "Message from #{sender_name}: #{string_message}"})
        end

        :gen_tcp.send(socket, "Message was broadcasted to everyone!\n")

      {:error, reason} ->
        IO.puts("Error: #{reason}")
        :gen_tcp.send(socket, reason <> "\n")
    end
  end
end

  defp handle_msg_command(socket, arguments) do
    [name | message_list] = arguments
    IO.inspect(name)
    string_message = Enum.join(message_list, " ")

    if String.trim(name) == "" or String.trim(string_message) == "" do
      :gen_tcp.send(
        socket,
        "Error: Invalid nickname or message! Nickname and message cannot be empty.\n"
      )
    else
      case GenServer.call({:global, Chat.BroadcastServer}, {:msg, name, self()}) do
        {:ok, receiver_pid, sender_name} ->
          send(receiver_pid, {:message, "Message from #{sender_name}: #{string_message}"})
          :gen_tcp.send(socket, "Message was broadcasted to #{name}!\n")

        {:error, reason} ->
          IO.puts("Error: #{reason}")
          :gen_tcp.send(socket, reason <> "\n")
      end
    end
  end

  defp validate_nickname(name) do
    Regex.match?(~r/^[a-zA-Z][a-zA-Z0-9_]{0,11}$/, name) and String.trim(name) != ""
  end

  defp handle_unknown_command(socket) do
    IO.puts("Unknown command")
    :gen_tcp.send(socket, "Unknown command\n")
  end
end
