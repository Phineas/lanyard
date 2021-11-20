defmodule Lanyard.KV.Interface do
  alias Lanyard.Connectivity.Redis
  alias Lanyard.Presence

  def get_all(user_id) do
    {:ok, %{kv: kv}} = Presence.get_presence(user_id)
    kv
  end

  def set(user_id, key, value) do
    Redis.hset("lanyard_kv:#{user_id}", key, value)

    kv = get_all(user_id)
    Presence.sync(user_id, %{kv: Map.put(kv, key, value)})
  end

  def del(user_id, key) do
    Redis.hdel("lanyard_kv:#{user_id}", key)

    kv = get_all(user_id)
    Presence.sync(user_id, %{kv: Map.delete(kv, key)})
  end
end
