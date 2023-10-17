defmodule Chat.Client do
  def chat(host, port) do
    {:ok, socket} =
      :gen_tcp.connect(host, port, [:binary, {:active, false}, {:packet, 0}])
    loop(socket)
  end

  def loop(socket) do
    case IO.gets("> ") do
      :eof ->
        :gen_tcp.close(socket)
      line ->
        :gen_tcp.send(socket, line)
        {:ok, reply} = :gen_tcp.recv(socket, 0)
        IO.write(reply)
        loop(socket)
    end
  end
end

with [host_str, port_str] <- System.argv(),
     {port, ""} <- Integer.parse(port_str)
do
  Chat.Client.connect(String.to_atom(host_str), port)
else
  _ -> Chat.Client.connect(:localhost, 6666)
end
