defmodule Chat.ProxyServer do
  use GenServer
  # passive server: need to call :gen_tcp.recv to receive data
  # passive server: need to call :gen_tcp.recv to receive data
  def start_link(port \\ 6666) do
    GenServer.start_link(__MODULE__, port)
  end

  @impl true
  def init(port \\ 6666) do
    opts = [:binary, {:packet, 0}, {:reuseaddr, true}, {:active, :once}]
    {:ok, socket} = :gen_tcp.listen(port, opts)
    spawn(fn -> accept(socket) end)
    # IO.puts("#{inspect(self())}: accepted connection #{inspect(conn)}")
    {:ok, socket}
  end

  # def accept(socket) do
  #   case :gen_tcp.accept(socket) do
  #     {:ok, conn} ->
  #       spawn(fn -> accept(socket) end)
  #       loop(conn)
  #     {:error, :closed} ->
  #       IO.puts(" cssonnection closed")
  #       :ok
  #   end
  # end

  #   def accept(socket) do
  #   {:ok, conn} = :gen_tcp.accept(socket)
  #   IO.puts("connected! ")

  #   spawn(fn -> accept(socket) end)
  #   IO.puts("#{inspect(self())}: accepted connection #{inspect(conn)}")
  #   loop(conn)
  # end

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
       hello = handle_client_command(socket, data)
       IO.inspect("hello")
       IO.inspect(hello)

       #:gen_tcp.send(socket, String.to_charlist(hello))

        :gen_tcp.send(socket, data)
        :inet.setopts(socket, [{:active, :once}])  # need to reset active once
        loop(socket)
        {:tcp_closed, ^socket} ->
          IO.puts("#{inspect(self())}: connection #{inspect(socket)} closed")
          :gen_tcp.close(socket)
        _ -> :ok
          loop(socket)
    end
  end

    def handle_client_command(socket, data) do
    [command | args] = String.split(data, ~r/\s+/)
    case command do
      "/LIST" -> handle_list_command(socket)
      "/NICK" -> hanle_nick_command(socket)
      _ -> handle_unknown_command()
    end
  end

    defp handle_list_command(socket) do
      IO.inspect("handle_list_command")
      result = GenServer.call({:global, Chat.BroadcastServer}, :list)

      IO.inspect("result")
      IO.inspect(result)
      result
  end

    defp handle_unknown_command do
    IO.puts("Unknown command")
  end
end

#   def start_link(port \\ 6666) do
#     GenServer.start_link(__MODULE__, port, name: __MODULE__)

#     IO.puts("Listening on port #{port}")
#   end

#   @impl true
#   def init(port \\ 6666) do
#     opts = [:binary, {:packet, 0}, {:reuseaddr, true}, {:active, false}]
#     {:ok, socket} = :gen_tcp.listen(port, opts)
#     # spawn(fn -> accept(socket) end)
#     IO.puts("Listening on port #{port}")
#     {:ok, socket}
#   end
# end
  # @impl true
  # def init(port) do
  #   {:ok, listener} = :gen_tcp.listen(port, [:binary, {:active, false}, {:reuseaddr, true}])
  #   {:ok, listener}
  # end

  # def accept(socket) do
  #   case :gen_tcp.accept(socket) do
  #     {:ok, conn} ->
  #       spawn(fn -> accept(socket) end)
  #       IO.puts("#{inspect(self())}: accepted connection #{inspect(conn)}")
  #       loop(conn)
  #     {:error, reason} ->
  #       IO.puts("Error accepting connection: #{inspect(reason)}")
  #       :ok
  #   end
  # end

  # defp loop(socket) do
  #   receive do
  #     {:tcp, ^socket, data} ->
  #       #:gen_tcp.send(socket, data)
  #       IO.inspect(data, label: "Received Data:")
  #       # handle_client_command(data)
  #       :inet.setopts(socket, [{:active, :once}])  # need to reset active once
  #       loop(socket)
  #     {:tcp_closed, ^socket} ->
  #       IO.puts("#{inspect(self())}: connection #{inspect(socket)} closed")
  #       :gen_tcp.close(socket)
  #     _ -> :ok
  #       loop(socket)
  #   end
  # end

  # def handle_client_command(data) do
  #   [command | args] = String.split(data, ~r/\s+/)
  #   case command do
  #     "/LIST" -> handle_list_command()
  #     _ -> handle_unknown_command()
  #   end
  # end

  # defp validate_nickname(name) do
  #   Regex.match?(~r/^[a-zA-Z][a-zA-Z0-9_]{0,9}$/, name)
  # end
  # # Implement the logic for each command
  # defp handle_list_command do
  #   result = GenServer.call(@broadcast_server, {"/LIST", self()})
  #   IO.inspect(result)
  #   IO.puts("Handling LIST command")
  # end

  # defp handle_unknown_command do
  #   IO.puts("Unknown command")
  # end
# end
