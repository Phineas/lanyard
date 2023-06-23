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

  def init(params) do
    compression =
      params
      |> Enum.find(fn {name, _value} -> name == "compression" end)
      |> case do
        {_name, "zlib_json"} -> :zlib
        _ -> :json
      end

    state = %__MODULE__{awaiting_init: true, encoding: "json", compression: compression}

    Lanyard.Metrics.Collector.inc(:gauge, :lanyard_connected_sessions)

    {:reply, :ok,
     construct_socket_msg(state.compression, %{op: 1, d: %{"heartbeat_interval" => 30000}}),
     state}
  end

  def handle_control({_message, [opcode: :ping]}, state) do
    {:ok, state}
  end

  def handle_in({json, _type}, state) do
    Lanyard.Metrics.Collector.inc(:counter, :lanyard_messages_inbound)

    case Jason.decode(json) do
      {:ok, json} when is_map(json) ->
        case json["op"] do
          2 ->
            if json["d"] == nil || !is_map(json["d"]) || map_size(json["d"]) == 0 do
              {:stop, :normal, {4005, "requires_data_object"}, state}
            else
              init_state =
                case json["d"] do
                  %{"subscribe_to_ids" => ids} ->
                    Logger.debug(
                      "Sockets | Socket initialized and subscribed to list: #{inspect(ids)}"
                    )

                    Presence.subscribe_to_ids_and_build(ids)

                  %{"subscribe_to_id" => id} ->
                    case GenRegistry.lookup(Lanyard.Presence, id) do
                      {:ok, pid} ->
                        {:ok, raw_data} = Presence.get_presence(id)
                        {_, presence} = Presence.build_pretty_presence(raw_data)

                        send(pid, {:add_subscriber, self()})

                        Logger.debug(
                          "Sockets | Socket initialized and subscribed to singleton: #{id}"
                        )

                        presence

                      _ ->
                        %{}
                    end

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

                  _ ->
                    nil
                end

              if init_state == nil do
                {:stop, :normal, {4006, "invalid_payload"}, state}
              else
                {:reply, :ok,
                 construct_socket_msg(state.compression, %{op: 0, t: "INIT_STATE", d: init_state}),
                 state}
              end
            end

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
            {:stop, :normal, {4004, "unknown_opcode"}, state}
        end

      _ ->
        {:stop, :normal, {4006, "invalid_payload"}, state}
    end
  end

  def handle_info({:remote_send, message}, state) do
    {:reply, :ok, construct_socket_msg(state.compression, message), state}
  end

  def terminate(_reason, _state) do
    :ets.insert(
      :global_subscribers,
      {"subscribers", List.delete(get_global_subscriber_list(), self())}
    )

    Lanyard.Metrics.Collector.dec(:gauge, :lanyard_connected_sessions)

    :ok
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
    Lanyard.Metrics.Collector.inc(:counter, :lanyard_messages_outbound)

    case compression do
      :zlib ->
        data = data |> Jason.encode!()

        z = :zlib.open()
        :zlib.deflateInit(z)

        data = :zlib.deflate(z, data, :finish)

        :zlib.deflateEnd(z)

        {:binary, data}

      _ ->
        data =
          data
          |> Jason.encode!()

        {:text, data}
    end
  end
end
