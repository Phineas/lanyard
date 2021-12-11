defmodule Lanyard.Connectivity.Redis do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: :local_redis_client)
  end

  def init(_) do
    {:ok, client} = Redix.start_link(host: Application.get_env(:lanyard, :redis_host), port: 6379)

    {:ok, %{client: client}}
  end

  def handle_call({:hgetall, key}, _from, state) do
    value = Redix.command(state[:client], ["HGETALL", key])

    {:reply, value, state}
  end

  def handle_call({:hget, key, field}, _from, state) do
    value = Redix.command(state[:client], ["HGET", key, field])

    {:reply, value, state}
  end

  def handle_call({:get, key}, _from, state) do
    value = Redix.command(state[:client], ["GET", key])

    {:reply, value, state}
  end

  def handle_cast({:set, key, value}, state) do
    Redix.command(state.client, ["SET", key, value])

    {:noreply, state}
  end

  def handle_cast({:del, key}, state) do
    Redix.command(state.client, ["DEL", key])

    {:noreply, state}
  end

  def handle_cast({:hset, key, field, value}, state) do
    Redix.command(state.client, ["HSET", key, field, value])

    {:noreply, state}
  end

  def handle_cast({:hincrby, key, field, amount}, state) do
    Redix.command(state.client, ["HINCRBY", key, field, amount])

    {:noreply, state}
  end

  def handle_cast({:hdel, key, field}, state) do
    Redix.command(state.client, ["HDEL", key, field])

    {:noreply, state}
  end

  def set(key, value) do
    GenServer.cast(:local_redis_client, {:set, key, value})
  end

  def del(key) do
    GenServer.cast(:local_redis_client, {:del, key})
  end

  def hdel(key, field) do
    GenServer.cast(:local_redis_client, {:hdel, key, field})
  end

  def hset(key, field, value) do
    GenServer.cast(:local_redis_client, {:hset, key, field, value})
  end

  def hincrby(key, field, amount) do
    GenServer.cast(:local_redis_client, {:hincrby, key, field, amount})
  end

  def hgetall(key) do
    {:ok, response} = GenServer.call(:local_redis_client, {:hgetall, key})

    response
    |> normalize_kv()
  end

  def hget(key, field) do
    {:ok, response} = GenServer.call(:local_redis_client, {:hget, key, field})

    response
    |> normalize_kv()
  end

  def get(key) do
    {:ok, response} = GenServer.call(:local_redis_client, {:get, key})

    response
  end

  defp normalize_kv(l) do
    l
    |> Enum.chunk_every(2)
    |> Map.new(fn [k, v] -> {k, v} end)
  end
end
