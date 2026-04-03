defmodule Lanyard.Connectivity.Migration do
  require Logger
  alias Lanyard.Connectivity.Redis
  alias Lanyard.Connectivity.MongoDB

  def migrate_api_keys_from_redis do
    Logger.info("Starting API Key migration from Redis to MongoDB...")

    case Redis.command(["KEYS", "user_api_key:*"]) do
      {:ok, keys} ->
        Logger.info("Found #{length(keys)} API keys to migrate.")

        Enum.each(keys, fn full_key ->
          user_id = String.replace(full_key, "user_api_key:", "")

          case Redis.get(full_key) do
            api_key when is_binary(api_key) ->
              Logger.info("Migrating key for user #{user_id}...")
              MongoDB.set_api_key(user_id, api_key)

            _ ->
              Logger.warning("No value found for key #{full_key}")
          end
        end)

        Logger.info("Migration complete.")

      {:error, reason} ->
        Logger.error("Failed to fetch keys from Redis: #{inspect(reason)}")
    end
  end

  def migrate_kv_from_redis do
    prefix = "lanyard:user_kv:"
    Logger.info("Starting KV migration from Redis to MongoDB...")

    case Redis.command(["KEYS", prefix <> "*"]) do
      {:ok, keys} ->
        Logger.info("Found #{length(keys)} KV stores to migrate.")

        Enum.each(keys, fn full_key ->
          user_id = String.replace(full_key, prefix, "")
          kv = Redis.hgetall(full_key)

          if map_size(kv) > 0 do
            # Decode values if they were JSON (like in Persistence layer)
            decoded_kv =
              for {k, v} <- kv, into: %{} do
                case Jason.decode(v) do
                  {:ok, decoded} -> {k, decoded}
                  _ -> {k, v}
                end
              end

            Logger.info("Migrating KV for user #{user_id}...")
            MongoDB.multiset_kv(user_id, decoded_kv)
          end
        end)

        Logger.info("KV Migration complete.")

      {:error, reason} ->
        Logger.error("Failed to fetch KV keys from Redis: #{inspect(reason)}")
    end
  end

  def migrate_last_seen_from_redis do
    prefix = "lanyard:user_last_seen:"
    Logger.info("Starting Last Seen migration from Redis to MongoDB...")

    case Redis.command(["KEYS", prefix <> "*"]) do
      {:ok, keys} ->
        Logger.info("Found #{length(keys)} Last Seen entries to migrate.")

        Enum.each(keys, fn full_key ->
          user_id = String.replace(full_key, prefix, "")

          case Redis.get(full_key) do
            {:ok, val} when is_binary(val) ->
              Logger.info("Migrating last seen for user #{user_id}...")
              MongoDB.upsert_last_seen(user_id, String.to_integer(val))

            _ ->
              :ok
          end
        end)

        Logger.info("Last Seen migration complete.")

      {:error, reason} ->
        Logger.error("Failed to fetch Last Seen keys: #{inspect(reason)}")
    end
  end

  def migrate_metrics_from_redis do
    key = "lanyard:metrics_v1"
    Logger.info("Starting Metrics migration from Redis to MongoDB...")

    case Redis.hgetall(key) do
      %{} = metrics when map_size(metrics) > 0 ->
        # Convert values to numbers
        normalized =
          for {k, v} <- metrics, into: %{} do
            case Integer.parse(v) do
              {num, _} -> {k, num}
              _ -> {k, v}
            end
          end

        MongoDB.store_metrics(normalized)
        Logger.info("Metrics migration complete.")

      _ ->
        Logger.warning("No metrics found in Redis to migrate.")
    end
  end
end
