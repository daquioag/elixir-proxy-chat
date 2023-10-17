def chat.proxyServer do
  @broadcast_server {:global, Chat.BroadcastServer}

  def start(port \\ 6666) do
    opts = [:binary, {:packet, 0}, {:reuseaddr, true}, {:active, false}]
    {:ok, socket} = :gen_tcp.listen(port, opts)
    spawn(fn -> accept(socket) end)
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
        #:gen_tcp.send(socket, data)
        handle_client_command(data)
        :inet.setopts(socket, [{:active, :once}])  # need to reset active once
        loop(socket)
      {:tcp_closed, ^socket} ->
        IO.puts("#{inspect(self())}: connection #{inspect(socket)} closed")
        :gen_tcp.close(socket)
      _ -> :ok
        loop(socket)
    end
  end

  def handle_client_command(data) do
    [command | args] = String.split(data, ~r/\s+/)
    case command do
      "/LIST" -> handle_list_command()
      _ -> handle_unknown_command()
    end
  end


  # Implement the logic for each command
  defp handle_list_command do
    result = GenServer.call(@broadcast_server, {"/LIST", self()})
    IO.inspect(result)
    IO.puts("Handling LIST command")
  end

  defp handle_unknown_command do
    IO.puts("Unknown command")
  end
end
