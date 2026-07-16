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

    Counter.new(
      name: :lanyard_http_exceptions_total,
      registry: @registry,
      labels: [],
      help: "HTTP requests that raised an exception during dispatch."
    )

    Histogram.new(
      name: :lanyard_http_request_duration_seconds,
      registry: @registry,
      labels: [],
      buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
      help: "HTTP request duration in seconds."
    )

    Counter.new(
      name: :lanyard_gateway_unhandled_ops_total,
      registry: @registry,
      labels: [:op],
      help: "Gateway opcodes received that have no handler clause."
    )

    Counter.new(
      name: :lanyard_gateway_client_starts_total,
      registry: @registry,
      labels: [],
      help: "Gateway client process starts (initial connect plus every restart)."
    )

    Counter.new(
      name: :lanyard_gateway_sessions_total,
      registry: @registry,
      labels: [:type],
      help: "Gateway sessions begun, by type (identify or resume)."
    )

    Histogram.new(
      name: :lanyard_heartbeat_ack_latency_seconds,
      registry: @registry,
      labels: [],
      buckets: [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
      help: "Round-trip latency between a heartbeat send and its ACK."
    )

    Gauge.new(
      name: :lanyard_global_subscribers,
      registry: @registry,
      labels: [],
      help: "Sockets subscribed to every presence (subscribe_to_all)."
    )

    Histogram.new(
      name: :lanyard_presence_fanout_size,
      registry: @registry,
      labels: [],
      buckets: [0, 1, 2, 5, 10, 25, 50, 100, 250, 500, 1000],
      help: "Subscriber count per presence broadcast."
    )

    Counter.new(
      name: :lanyard_presence_subscriptions_total,
      registry: @registry,
      labels: [:op],
      help: "Presence subscriber changes, by op (subscribe, unsubscribe, down)."
    )

    Counter.new(
      name: :lanyard_presence_cache_lookups_total,
      registry: @registry,
      labels: [:result],
      help: "Cached-presence ETS lookups, by result (hit or miss)."
    )

    Counter.new(
      name: :lanyard_discord_api_requests_total,
      registry: @registry,
      labels: [:status],
      help: "Outbound Discord REST responses, by status class."
    )

    Counter.new(
      name: :lanyard_cdn_proxy_requests_total,
      registry: @registry,
      labels: [:status],
      help: "Avatar CDN proxy upstream responses, by status class."
    )

    Counter.new(
      name: :lanyard_global_sync_messages_total,
      registry: @registry,
      labels: [:type],
      help: "Cross-node global-sync messages (published, applied, ignored, invalid)."
    )

    Counter.new(
      name: :lanyard_socket_closes_total,
      registry: @registry,
      labels: [:code],
      help: "Socket error closes, by close code."
    )

    Counter.new(
      name: :lanyard_socket_inits_total,
      registry: @registry,
      labels: [:type, :compression],
      help: "Socket op-2 inits, by subscription type and compression mode."
    )

    Histogram.new(
      name: :lanyard_redis_command_duration_seconds,
      registry: @registry,
      labels: [:command],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5],
      help: "Redis command duration in seconds."
    )

    Counter.new(
      name: :lanyard_kv_validation_failures_total,
      registry: @registry,
      labels: [:reason],
      help: "KV writes rejected by validation, by reason."
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

  def observe(:histogram, stat, value) do
    Histogram.observe([name: stat, registry: @registry], value)
  end

  def observe(:histogram, stat, labels, value) when is_list(labels) do
    Histogram.observe([name: stat, registry: @registry, labels: labels], value)
  end

  def status_class(429), do: "429"
  def status_class(status) when status < 300, do: "2xx"
  def status_class(status) when status < 400, do: "3xx"
  def status_class(status) when status < 500, do: "4xx"
  def status_class(_status), do: "5xx"

  def refresh_runtime_gauges do
    mem = :erlang.memory()

    set(:gauge, :lanyard_erlang_memory_total_bytes, Keyword.get(mem, :total, 0))
    set(:gauge, :lanyard_erlang_memory_processes_bytes, Keyword.get(mem, :processes, 0))
    set(:gauge, :lanyard_erlang_memory_binary_bytes, Keyword.get(mem, :binary, 0))
    set(:gauge, :lanyard_erlang_memory_ets_bytes, Keyword.get(mem, :ets, 0))
    set(:gauge, :lanyard_erlang_process_count, :erlang.system_info(:process_count))
    set(:gauge, :lanyard_erlang_run_queue, :erlang.statistics(:total_run_queue_lengths))
    set(:gauge, :lanyard_redis_client_queue_length, redis_client_queue_length())
    set(:gauge, :lanyard_global_subscribers, length(Lanyard.SocketHandler.get_global_subscriber_list()))
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
