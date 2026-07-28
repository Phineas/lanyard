defmodule Lanyard.KV.Interface do
  alias Lanyard.Connectivity.Redis
  alias Lanyard.Presence

  @key_count_limit 512
  @key_length_limit 255
  @value_length_limit 30000

  def get_all(user_id) do
    {:ok, %{kv: kv}} = Presence.get_presence(user_id)
    kv
  end

  def get(user_id, key) do
    case Presence.get_presence(user_id) do
      {:ok, %{kv: %{^key => value}}} ->
        {:ok, value}

      _ ->
        {:error, "Key #{key} not found in KV"}
    end
  end

  def set(user_id, key, value) do
    kv = get_all(user_id)
    new_key_count = Map.merge(kv, %{key => value}) |> Map.keys() |> length

    cond do
      new_key_count > @key_count_limit ->
        Lanyard.Metrics.Collector.inc(:counter, :lanyard_kv_validation_failures_total, [
          "key_limit"
        ])

        {:error, "request would exceed key limit (#{@key_count_limit}), please delete keys first"}

      true ->
        case validate_pair({key, value}) do
          {:error, _msg} = err ->
            err

          {:ok} ->
            Redis.hset("lanyard_kv:#{user_id}", key, value)
            Presence.sync(user_id, %{kv: Map.put(kv, key, value)})
            {:ok, value}
        end
    end
  end

  def multiset(user_id, map) when is_map(map) do
    with {:ok} <- validate_pairs(map) do
      kv = get_all(user_id)
      new_key_count = Map.merge(kv, map) |> Map.keys() |> length

      cond do
        new_key_count > @key_count_limit ->
          Lanyard.Metrics.Collector.inc(:counter, :lanyard_kv_validation_failures_total, [
            "key_limit"
          ])

          {:error, "request would exceed the key limit (#{@key_count_limit}), please delete some keys first"}

        true ->
          Redis.hset("lanyard_kv:#{user_id}", map_to_list(map))
          Presence.sync(user_id, %{kv: Map.merge(kv, map)})
          {:ok}
      end
    end
  end

  def del(user_id, key) do
    Redis.hdel("lanyard_kv:#{user_id}", key)

    kv = get_all(user_id)
    Presence.sync(user_id, %{kv: Map.delete(kv, key)})
  end

  def validate_pair({key, value}) do
    cond do
      String.length(key) > @key_length_limit ->
        Lanyard.Metrics.Collector.inc(:counter, :lanyard_kv_validation_failures_total, [
          "key_too_long"
        ])

        {:error, "key must be #{@key_length_limit} characters or less"}

      not String.match?(key, ~r/^[a-zA-Z0-9_]*$/) ->
        Lanyard.Metrics.Collector.inc(:counter, :lanyard_kv_validation_failures_total, [
          "key_invalid"
        ])

        {:error, "key must be alphanumeric (a-zA-Z0-9_)"}

      String.length(value) > @value_length_limit ->
        Lanyard.Metrics.Collector.inc(:counter, :lanyard_kv_validation_failures_total, [
          "value_too_long"
        ])

        {:error, "value must be #{@value_length_limit} characters or less"}

      true ->
        {:ok}
    end
  end

  defp validate_pairs(map) do
    Enum.reduce_while(map, {:ok}, fn pair, _acc ->
      case validate_pair(pair) do
        {:ok} -> {:cont, {:ok}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp map_to_list(map) when is_map(map) do
    map |> Enum.reduce([], fn {k, v}, acc -> [k, v | acc] end)
  end
end
