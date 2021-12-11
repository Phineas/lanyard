defmodule Lanyard.SocketHandler do
  require Logger

  alias Lanyard.Presence

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
    compression =
      request
      |> :cowboy_req.parse_qs()
      |> Enum.find(fn {name, _value} -> name == "compression" end)
      |> case do
        {_name, "zlib_json"} -> :zlib
        _ -> :json
      end

    state = %__MODULE__{awaiting_init: true, encoding: "json", compression: compression}

    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    {:reply,
     construct_socket_msg(state.compression, %{op: 1, d: %{"heartbeat_interval" => 30000}}),
     state}
  end

  def websocket_handle({:ping, _binary}, state) do
    {:ok, state}
  end

  def websocket_handle({_type, json}, state) do
    with {:ok, json} <- Poison.decode(json) do
      case json["op"] do
        2 ->
          init_state =
            case json["d"] do
              %{"subscribe_to_ids" => ids} ->
                Logger.debug(
                  "Sockets | Socket initialized and subscribed to list: #{inspect(ids)}"
                )

                Presence.subscribe_to_ids_and_build(ids)

              %{"subscribe_to_id" => id} ->
                {:ok, pid} = GenRegistry.lookup(Lanyard.Presence, id)

                {:ok, raw_data} = Presence.get_presence(id)
                {_, presence} = Presence.build_pretty_presence(raw_data)

                send(pid, {:add_subscriber, self()})

                Logger.debug("Sockets | Socket initialized and subscribed to singleton: #{id}")
                presence

              %{"subscribe_to_all" => true} ->
                ids =
                  GenRegistry.reduce(Lanyard.Presence, [], fn {id, _pid}, acc ->
                    [id | acc]
                  end)

                :ets.insert(
                  :global_subscribers,
                  {"subscribers", [self() | get_global_subscriber_list()]}
                )

                Process.flag(:trap_exit, true)

                Presence.subscribe_to_ids_and_build(ids)
            end

          {:reply,
           construct_socket_msg(state.compression, %{op: 0, t: "INIT_STATE", d: init_state}),
           state}

        # Used for heartbeating
        3 ->
          {:ok, state}

        # Unsubscribe
        4 ->
          case json["d"] do
            %{"unsubscribe_from_id" => id} ->
              {:ok, pid} = GenRegistry.lookup(Lanyard.Presence, id)

              unless not Process.alive?(pid) do
                send(pid, {:remove_subscriber, pid})
              end
          end

          {:ok, state}

        _ ->
          {:reply, {:close, 4004, "unknown_opcode"}, state}
      end
    end
  end

  def websocket_info({:remote_send, message}, state) do
    {:reply, construct_socket_msg(state.compression, message), state}
  end

  def terminate(_reason, _req, state) do
    :ets.insert(
      :global_subscribers,
      {"subscribers", List.delete(get_global_subscriber_list(), self())}
    )

    {:ok, state}
  end

  def get_global_subscriber_list do
    case :ets.lookup(:global_subscribers, "subscribers") do
      [{_, subscribers}] ->
        subscribers

      _ ->
        []
    end
  end

  defp construct_socket_msg(compression, data) do
    case compression do
      :zlib ->
        data = data |> Poison.encode!()

        z = :zlib.open()
        :zlib.deflateInit(z)

        data = :zlib.deflate(z, data, :finish)

        :zlib.deflateEnd(z)

        {:binary, data}

      _ ->
        data =
          data
          |> Poison.encode!()

        {:text, data}
    end
  end
end
