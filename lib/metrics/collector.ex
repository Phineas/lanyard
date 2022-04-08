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
      name: :lanyard_discord_messages_sent,
      registry: @registry,
      labels: [],
      help: "Messages sent to discord count"
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

  def inc(:gauge, stat, value) do
    Gauge.inc([name: stat, registry: @registry], value)
  end

  def set(:gauge, stat, value) do
    Gauge.set([name: stat, registry: @registry], value)
  end
end
