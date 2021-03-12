defmodule Lanyard.SocketHandler do
  require Logger

  @type t :: %{
    awaiting_init: boolean,
    encoding: String.t(),
    compression: String.t()
  }

  defstruct awaiting_init: true,
            encoding: nil,
            compression: nil

  @behaviour :cowboy_websocket

  def init(request, _state) do
    compression = request
    |> :cowboy_req.parse_qs
    |> Enum.find(fn {name, _value} -> name == "compression" end)
    |> case do
      {_name, "zlib_json"} -> :zlib
      _ -> :json
    end

    state = %__MODULE__{awaiting_init: true, encoding: "json", compression: compression}

    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    Process.send_after(self(), {:finish_awaiting}, 10_000)

    {:reply, construct_socket_msg(state.compression, %{op: 1, d: %{"heartbeat_interval" => 30000}}), state}
  end

  def websocket_info({:finish_awaiting}, state) do
    if state.awaiting_init do
      {:stop, state}
    else
      {:ok, state}
    end
  end

  def websocket_handle({:ping, _binary}, state) do
    {:ok, state}
  end

  def websocket_handle({_type, json}, state) do
    IO.inspect self()
    with {:ok, json} <- Poison.decode(json) do
      case json["op"] do
        2 ->
          %{"subscribe_to_ids" => ids} = json["d"]


        3 -> {:ok, state} # Used for heartbeating
        _ -> {:reply, {:close, 4004, "unknown_opcode"}, state}
      end
    end
  end

  defp construct_socket_msg(compression, data) do
    case compression do
      :zlib ->
        data = data |> Poison.encode!

        z = :zlib.open()
        :zlib.deflateInit(z)

        data = :zlib.deflate(z, data, :finish)

        :zlib.deflateEnd(z)

        {:binary, data}
      _ ->
        data = data
        |> Poison.encode!

        {:text, data}
    end
  end
end
