defmodule Lanyard.Metrics.Collector do
  use Prometheus.Metric

  @registry :lanyard_registry

  def start do
    Gauge.new(
      name: :lanyard_connected_sessions,
      registry: @registry,
      labels: [],
      help: "Currently connected sessions count."
    )

    Counter.new(
      name: :lanyard_messages_outbound,
      registry: @registry,
      labels: [],
      help: "Total socket messages outbout."
    )

    Counter.new(
      name: :lanyard_messages_inbound,
      registry: @registry,
      labels: [],
      help: "Total messages received count."
    )

    Counter.new(
      name: :lanyard_presence_updates,
      registry: @registry,
      labels: [],
      help: "Presence updates received count."
    )

    Gauge.new(
      name: :lanyard_monitored_users,
      registry: @registry,
      labels: [],
      help: "Users monitored by Lanyard count."
    )

    Counter.new(
      name: :lanyard_2xx_responses,
      registry: @registry,
      labels: [],
      help: "2xx http responses"
    )

    Counter.new(
      name: :lanyard_4xx_responses,
      registry: @registry,
      labels: [],
      help: "4xx http responses"
    )

    Counter.new(
      name: :lanyard_5xx_responses,
      registry: @registry,
      labels: [],
      help: "5xx http responses"
    )

    Counter.new(
      name: :lanyard_3xx_responses,
      registry: @registry,
      labels: [],
      help: "3xx http responses"
    )

    Counter.new(
      name: :lanyard_discord_messages_sent,
      registry: @registry,
      labels: [],
      help: "Messages sent to discord count"
    )

    Gauge.new(
      name: :lanyard_gateway_connected,
      registry: @registry,
      labels: [],
      help: "1 while the Discord gateway is connected and READY, 0 otherwise."
    )

    Counter.new(
      name: :lanyard_gateway_events_total,
      registry: @registry,
      labels: [:event],
      help: "Discord gateway dispatch events received, by event name."
    )

    Counter.new(
      name: :lanyard_gateway_reconnects_total,
      registry: @registry,
      labels: [:cause],
      help: "Discord gateway connection drops that trigger a resume/reconnect, by cause."
    )

    Counter.new(
      name: :lanyard_heartbeats_sent_total,
      registry: @registry,
      labels: [],
      help: "Heartbeats sent to the Discord gateway."
    )

    Counter.new(
      name: :lanyard_heartbeat_stale_total,
      registry: @registry,
      labels: [],
      help: "Heartbeats that went unacked (stale), forcing a reconnect."
    )

    Counter.new(
      name: :lanyard_redis_commands_total,
      registry: @registry,
      labels: [:command, :status],
      help: "Redis commands issued, by command and ok/error status."
    )

    Gauge.new(
      name: :lanyard_redis_client_queue_length,
      registry: @registry,
      labels: [],
      help: "Message-queue length of the single Redis client GenServer (head-of-line backlog)."
    )

    Gauge.new(
      name: :lanyard_erlang_memory_total_bytes,
      registry: @registry,
      labels: [],
      help: "Total memory allocated by the Erlang VM."
    )

    Gauge.new(
      name: :lanyard_erlang_memory_processes_bytes,
      registry: @registry,
      labels: [],
      help: "Memory allocated to Erlang processes."
    )

    Gauge.new(
      name: :lanyard_erlang_memory_binary_bytes,
      registry: @registry,
      labels: [],
      help: "Memory allocated to binaries (presence payloads live here)."
    )

    Gauge.new(
      name: :lanyard_erlang_memory_ets_bytes,
      registry: @registry,
      labels: [],
      help: "Memory allocated to ETS tables (cached presences / global subscribers)."
    )

    Gauge.new(
      name: :lanyard_erlang_process_count,
      registry: @registry,
      labels: [],
      help: "Number of live Erlang processes (one per monitored user + one per socket)."
    )

    Gauge.new(
      name: :lanyard_erlang_run_queue,
      registry: @registry,
      labels: [],
      help: "Total run-queue length across all schedulers."
    )
  end

  def dec(:gauge, stat) do
    Gauge.dec(name: stat, registry: @registry)
  end

  def inc(:gauge, stat) do
    Gauge.inc(name: stat, registry: @registry)
  end

  def inc(:counter, stat) do
    Counter.inc(name: stat, registry: @registry)
  end

  def inc(:counter, stat, labels) when is_list(labels) do
    Counter.inc(name: stat, registry: @registry, labels: labels)
  end

  def inc(:gauge, stat, value) do
    Gauge.inc([name: stat, registry: @registry], value)
  end

  def set(:gauge, stat, value) do
    Gauge.set([name: stat, registry: @registry], value)
  end

  def refresh_runtime_gauges do
    mem = :erlang.memory()

    set(:gauge, :lanyard_erlang_memory_total_bytes, Keyword.get(mem, :total, 0))
    set(:gauge, :lanyard_erlang_memory_processes_bytes, Keyword.get(mem, :processes, 0))
    set(:gauge, :lanyard_erlang_memory_binary_bytes, Keyword.get(mem, :binary, 0))
    set(:gauge, :lanyard_erlang_memory_ets_bytes, Keyword.get(mem, :ets, 0))
    set(:gauge, :lanyard_erlang_process_count, :erlang.system_info(:process_count))
    set(:gauge, :lanyard_erlang_run_queue, :erlang.statistics(:total_run_queue_lengths))
    set(:gauge, :lanyard_redis_client_queue_length, redis_client_queue_length())
  end

  defp redis_client_queue_length do
    case Process.whereis(:local_redis_client) do
      nil ->
        0

      pid ->
        case Process.info(pid, :message_queue_len) do
          {:message_queue_len, len} -> len
          _ -> 0
        end
    end
  end
end
