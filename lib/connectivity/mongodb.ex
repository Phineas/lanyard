defmodule Lanyard.Connectivity.MongoDB do
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    uri = Application.get_env(:lanyard, :mongodb_uri)
    database = Application.get_env(:lanyard, :mongodb_database) || "lanyard"

    if uri do
      {:ok, pid} =
        Mongo.start_link(
          url: uri,
          database: database,
          name: :mongo,
          ssl: true,
          ssl_opts: [
            verify: :verify_peer,
            cacertfile: CAStore.file_path(),
            depth: 3,
            customize_hostname_check: [
              match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
            ]
          ],
          pool_size: 50,
          idle_interval: 10_000,
          queue_target: 1000
        )

      {:ok, %{pid: pid}, {:continue, :ensure_indexes}}
    else
      Logger.warning("MongoDB URI not set, persistence will be disabled.")
      {:ok, %{pid: nil}}
    end
  end

  def handle_continue(:ensure_indexes, state) do
    if state[:pid] do
      # Ensure indexes for API keys
      Mongo.create_indexes(:mongo, "api_keys", [%{key: %{"user_id" => 1}, unique: true}])
      Mongo.create_indexes(:mongo, "api_keys", [%{key: %{"key" => 1}, unique: true}])
    end

    {:noreply, state}
  rescue
    e ->
      Logger.error("MongoDB index creation failed: #{inspect(e)}")
      {:noreply, state}
  end

  #
  # Public API
  #

  def upsert_last_seen(user_id, timestamp_ms) do
    user_id = normalize_id(user_id)

    Mongo.update_one(
      :mongo,
      "last_seen",
      %{"user_id" => user_id},
      %{"$set" => %{"timestamp" => timestamp_ms, "updated_at" => DateTime.utc_now()}},
      upsert: true
    )
  rescue
    e -> Logger.error("MongoDB upsert_last_seen failed for #{user_id}: #{inspect(e)}")
  end

  def get_last_seen(user_id) do
    user_id = normalize_id(user_id)

    case Mongo.find_one(:mongo, "last_seen", %{"user_id" => user_id}) do
      nil -> nil
      %{} = doc -> doc["timestamp"]
      {:error, _err} -> nil
      _ -> nil
    end
  rescue
    e ->
      Logger.error("MongoDB get_last_seen failed for #{user_id}: #{inspect(e)}")
      nil
  end

  def set_kv(user_id, key, value) do
    user_id = normalize_id(user_id)

    Mongo.update_one(
      :mongo,
      "kv",
      %{"user_id" => user_id},
      %{"$set" => %{"kv.#{key}" => value}},
      upsert: true
    )
  rescue
    e -> Logger.error("MongoDB set_kv failed for #{user_id}: #{inspect(e)}")
  end

  def multiset_kv(user_id, map) do
    user_id = normalize_id(user_id)
    update = for {k, v} <- map, into: %{}, do: {"kv.#{k}", v}

    Mongo.update_one(
      :mongo,
      "kv",
      %{"user_id" => user_id},
      %{"$set" => update},
      upsert: true
    )
  rescue
    e -> Logger.error("MongoDB multiset_kv failed for #{user_id}: #{inspect(e)}")
  end

  def get_all_kv(user_id) do
    user_id = normalize_id(user_id)

    case Mongo.find_one(:mongo, "kv", %{"user_id" => user_id}) do
      nil -> %{}
      %{} = doc -> doc["kv"] || %{}
      {:error, _err} -> %{}
      _ -> %{}
    end
  rescue
    e ->
      Logger.error("MongoDB get_all_kv failed for #{user_id}: #{inspect(e)}")
      %{}
  end

  def delete_kv(user_id, key) do
    user_id = normalize_id(user_id)

    Mongo.update_one(
      :mongo,
      "kv",
      %{"user_id" => user_id},
      %{"$unset" => %{"kv.#{key}" => ""}}
    )
  rescue
    e -> Logger.error("MongoDB delete_kv failed for #{user_id}: #{inspect(e)}")
  end

  def set_api_key(user_id, key) do
    user_id = normalize_id(user_id)

    # First, delete any existing mapping for this user
    delete_api_key_by_user_id(user_id)

    # Then insert the new one
    Mongo.insert_one(:mongo, "api_keys", %{
      "user_id" => user_id,
      "key" => key,
      "created_at" => DateTime.utc_now()
    })
  rescue
    e -> Logger.error("MongoDB set_api_key failed for #{user_id}: #{inspect(e)}")
  end

  def get_user_id_by_api_key(key) do
    case Mongo.find_one(:mongo, "api_keys", %{"key" => key}) do
      nil -> nil
      %{} = doc -> doc["user_id"]
      {:error, _err} -> nil
      _ -> nil
    end
  rescue
    e ->
      Logger.error("MongoDB get_user_id_by_api_key failed: #{inspect(e)}")
      nil
  end

  def get_api_key_by_user_id(user_id) do
    user_id = normalize_id(user_id)

    case Mongo.find_one(:mongo, "api_keys", %{"user_id" => user_id}) do
      nil -> nil
      %{} = doc -> doc["key"]
      {:error, _err} -> nil
      _ -> nil
    end
  rescue
    e ->
      Logger.error("MongoDB get_api_key_by_user_id failed for #{user_id}: #{inspect(e)}")
      nil
  end

  def delete_api_key_by_user_id(user_id) do
    user_id = normalize_id(user_id)

    Mongo.delete_many(:mongo, "api_keys", %{"user_id" => user_id})
  rescue
    e -> Logger.error("MongoDB delete_api_key_by_user_id failed for #{user_id}: #{inspect(e)}")
  end

  def get_monitoring_since(user_id) do
    user_id = normalize_id(user_id)

    # 1. Try "monitoring" collection (my new default)
    # 2. Try "users" collection (common in some forks)
    # 3. Try "kv" collection (as a special key)
    
    with nil <- Mongo.find_one(:mongo, "monitoring", %{"user_id" => user_id}) |> get_since(),
         nil <- Mongo.find_one(:mongo, "users", %{"user_id" => user_id}) |> get_since(),
         nil <- Mongo.find_one(:mongo, "kv", %{"user_id" => user_id}) |> get_since_from_kv() do
      nil
    else
      val -> val
    end
  rescue
    e ->
      Logger.error("MongoDB get_monitoring_since failed for #{user_id}: #{inspect(e)}")
      nil
  end

  defp get_since(nil), do: nil
  defp get_since(%{"since" => val}), do: val
  defp get_since(%{"monitoring_since" => val}), do: val
  defp get_since(_), do: nil

  defp get_since_from_kv(nil), do: nil
  defp get_since_from_kv(%{"kv" => %{"monitoring_since" => val}}), do: val
  defp get_since_from_kv(_), do: nil

  def set_monitoring_since(user_id, timestamp_ms) do
    user_id = normalize_id(user_id)

    Mongo.update_one(
      :mongo,
      "monitoring",
      %{"user_id" => user_id},
      %{"$setOnInsert" => %{"since" => timestamp_ms}},
      upsert: true
    )
  rescue
    e -> Logger.error("MongoDB set_monitoring_since failed for #{user_id}: #{inspect(e)}")
  end

  def delete_api_key_by_key(key) do
    Mongo.delete_many(:mongo, "api_keys", %{"key" => key})
  rescue
    e -> Logger.error("MongoDB delete_api_key_by_key failed: #{inspect(e)}")
  end

  def store_metrics(metrics) do
    if state_pid_present?() do
      Mongo.update_one(
        :mongo,
        "metrics",
        %{"type" => "global"},
        %{"$set" => Map.merge(metrics, %{"updated_at" => DateTime.utc_now()})},
        upsert: true
      )
    end
  rescue
    e -> Logger.error("MongoDB store_metrics failed: #{inspect(e)}")
  end

  def get_global_metrics do
    if state_pid_present?() do
      case Mongo.find_one(:mongo, "metrics", %{"type" => "global"}) do
        nil -> %{}
        %{} = doc -> Map.delete(doc, "_id") |> Map.delete("type")
        _ -> %{}
      end
    else
      %{}
    end
  rescue
    e ->
      Logger.error("MongoDB get_global_metrics failed: #{inspect(e)}")
      %{}
  end

  defp state_pid_present? do
    case GenServer.whereis(:mongo) do
      nil -> false
      _ -> true
    end
  end

  defp normalize_id(user_id) when is_integer(user_id), do: Integer.to_string(user_id)
  defp normalize_id(user_id), do: user_id
end
