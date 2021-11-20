defmodule Lanyard.KV.Interface do
  alias Lanyard.Connectivity.Redis
  alias Lanyard.Presence

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

    cond do
      Map.keys(kv) |> length > 511 ->
        {:error, "request would exceed key limit (512), please delete keys first"}

      String.length(key) > 255 ->
        {:error, "key must be 255 characters or less"}

      not String.match?(key, ~r/^[a-zA-Z0-9_]*$/) ->
        {:error, "key must be alphanumeric (a-zA-Z0-9_)"}

      String.length(value) > 30000 ->
        {:error, "value must be 30000 characters or less"}

      true ->
        Redis.hset("lanyard_kv:#{user_id}", key, value)
        Presence.sync(user_id, %{kv: Map.put(kv, key, value)})

        {:ok, value}
    end
  end

  def del(user_id, key) do
    Redis.hdel("lanyard_kv:#{user_id}", key)

    kv = get_all(user_id)
    Presence.sync(user_id, %{kv: Map.delete(kv, key)})
  end
end
