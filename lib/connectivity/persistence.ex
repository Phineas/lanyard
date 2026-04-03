defmodule Lanyard.Connectivity.Persistence do
  require Logger
  alias Lanyard.Connectivity.MongoDB
  alias Lanyard.Connectivity.Redis

  @metrics_redis_key "lanyard:metrics_v1"
  @last_seen_redis_prefix "lanyard:user_last_seen:"
  @monitoring_since_redis_prefix "lanyard:user_monitoring_since:"
  @kv_redis_prefix "lanyard:user_kv:"

  #
  # Monitoring Since
  #

  def set_monitoring_since(user_id, timestamp) do
    MongoDB.set_monitoring_since(user_id, timestamp)
    Redis.set(@monitoring_since_redis_prefix <> to_string(user_id), to_string(timestamp))
  end

  def get_monitoring_since(user_id) do
    mongo_since = MongoDB.get_monitoring_since(user_id)

    if mongo_since do
      mongo_since
    else
      # Try several Redis prefixes before giving up
      prefixes = [
        @monitoring_since_redis_prefix,
        "user_monitoring_since:",
        "monitoring:"
      ]

      result =
        Enum.find_value(prefixes, fn prefix ->
          case Redis.get(prefix <> to_string(user_id)) do
            {:ok, val} when is_binary(val) -> String.to_integer(val)
            _ -> nil
          end
        end)

      if result do
        result
      else
        # Last resort: check the KV store for this user
        kv = get_all_kv(user_id)
        kv["monitoring_since"]
      end
    end
  end

  #
  # User KV
  #

  def set_kv(user_id, key, value) do
    MongoDB.set_kv(user_id, key, value)
    Redis.hset(@kv_redis_prefix <> to_string(user_id), [key, Jason.encode!(value)])
  end

  def multiset_kv(user_id, map) do
    MongoDB.multiset_kv(user_id, map)
    redis_payload = for {k, v} <- map, into: [], do: [to_string(k), Jason.encode!(v)]
    Redis.hset(@kv_redis_prefix <> to_string(user_id), List.flatten(redis_payload))
  end

  def delete_kv(user_id, key) do
    MongoDB.delete_kv(user_id, key)
    Redis.hdel(@kv_redis_prefix <> to_string(user_id), key)
  end

  def get_all_kv(user_id) do
    # Try MongoDB first
    mongo_kv = MongoDB.get_all_kv(user_id)

    if map_size(mongo_kv) > 0 do
      mongo_kv
    else
      # Fallback to Redis
      case Redis.hgetall(@kv_redis_prefix <> to_string(user_id)) do
        %{} = redis_kv when map_size(redis_kv) > 0 ->
          for {k, v} <- redis_kv, into: %{}, do: {k, decode_json(v)}

        _ ->
          %{}
      end
    end
  end

  #
  # Last Seen
  #

  def upsert_last_seen(user_id, timestamp) do
    MongoDB.upsert_last_seen(user_id, timestamp)
    Redis.set(@last_seen_redis_prefix <> to_string(user_id), to_string(timestamp))
  end

  def get_last_seen(user_id) do
    mongo_last_seen = MongoDB.get_last_seen(user_id)

    if mongo_last_seen do
      mongo_last_seen
    else
      case Redis.get(@last_seen_redis_prefix <> to_string(user_id)) do
        {:ok, val} when is_binary(val) -> String.to_integer(val)
        _ -> nil
      end
    end
  end

  #
  # Metrics
  #

  def store_metrics(metrics) do
    MongoDB.store_metrics(metrics)

    # Also store in Redis just in case
    redis_metrics = for {k, v} <- metrics, into: [], do: [to_string(k), to_string(v)]
    Redis.hset(@metrics_redis_key, List.flatten(redis_metrics))
  end

  def get_global_metrics do
    mongo_metrics = MongoDB.get_global_metrics()

    if map_size(mongo_metrics) > 0 do
      mongo_metrics
    else
      case Redis.hgetall(@metrics_redis_key) do
        %{} = redis_metrics when map_size(redis_metrics) > 0 ->
          for {k, v} <- redis_metrics, into: %{}, do: {k, parse_num(v)}

        _ ->
          %{}
      end
    end
  end

  defp decode_json(raw) do
    Jason.decode!(raw)
  rescue
    _ -> raw
  end

  defp parse_num(raw) do
    String.to_integer(raw)
  rescue
    _ -> raw
  end
end
