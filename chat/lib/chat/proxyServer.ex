defmodule Chat.ProxyServer do
  use GenServer
  def start_link(port \\ 6666) do
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

      {:tcp_closed, ^socket} ->
        IO.puts("#{inspect(self())}: connection #{inspect(socket)} closed")
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

    if validate_nickname(nickname) do
      {_, result} = GenServer.call({:global, Chat.BroadcastServer}, {:nick, self(), nickname})
      IO.inspect(result)
      :gen_tcp.send(socket, result <> "\n")
    else
      :gen_tcp.send(socket, "Invalid Name. Name not added! \n")
    end
  end

  defp handle_bc_command(socket, message_list) do
    IO.inspect("handle_bc_command")
    string_message = Enum.join(message_list, " ")
    trimmed_string_message = String.trim(string_message)
    if trimmed_string_message == "" do
      :gen_tcp.send(socket, "The broadcast message cannot be empty \n")
    end

    case GenServer.call({:global, Chat.BroadcastServer}, {:bc, string_message}) do
      {:ok, message} ->
          :gen_tcp.send(socket, message <> "\n")
        {:error, reason} ->
          IO.puts("Error: #{reason}")
          :gen_tcp.send(socket, reason <> "\n")
      end
    end

  defp handle_bc_command2(socket, message_list) do
    string_message = Enum.join(message_list, " ")
    case GenServer.call({:global, Chat.BroadcastServer}, {:bc, string_message}) do
      {:ok, pid_list} ->
        # Handle the case where the call was successful
        for pid <- pid_list do
          send(pid, string_message)
        end
        :gen_tcp.send(socket, "Message was broadcasted to everyone")

        {:error, reason} ->
          IO.puts("Error: #{reason}")
          :gen_tcp.send(socket, reason)
      end
  end

  defp validate_nickname(name) do
    Regex.match?(~r/^[a-zA-Z][a-zA-Z0-9_]{0,9}$/, name)
  end

  defp handle_unknown_command(socket) do
    IO.puts("Unknown command")
    :gen_tcp.send(socket, "Unknown command\n")
  end
end
