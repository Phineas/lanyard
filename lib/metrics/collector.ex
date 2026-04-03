defmodule Lanyard.Metrics.Collector do
  use Prometheus.Metric

  @registry :lanyard_registry

  def start(initial_values \\ %{}) do
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

    if v = initial_values["lanyard_messages_outbound"],
      do: Counter.inc([name: :lanyard_messages_outbound, registry: @registry], v)

    Counter.new(
      name: :lanyard_messages_inbound,
      registry: @registry,
      labels: [],
      help: "Total messages received count."
    )

    if v = initial_values["lanyard_messages_inbound"],
      do: Counter.inc([name: :lanyard_messages_inbound, registry: @registry], v)

    Counter.new(
      name: :lanyard_presence_updates,
      registry: @registry,
      labels: [],
      help: "Presence updates received count."
    )

    if v = initial_values["lanyard_presence_updates"],
      do: Counter.inc([name: :lanyard_presence_updates, registry: @registry], v)

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

    if v = initial_values["lanyard_2xx_responses"],
      do: Counter.inc([name: :lanyard_2xx_responses, registry: @registry], v)

    Counter.new(
      name: :lanyard_4xx_responses,
      registry: @registry,
      labels: [],
      help: "4xx http responses"
    )

    if v = initial_values["lanyard_4xx_responses"],
      do: Counter.inc([name: :lanyard_4xx_responses, registry: @registry], v)

    Counter.new(
      name: :lanyard_5xx_responses,
      registry: @registry,
      labels: [],
      help: "5xx http responses"
    )

    if v = initial_values["lanyard_5xx_responses"],
      do: Counter.inc([name: :lanyard_5xx_responses, registry: @registry], v)

    Counter.new(
      name: :lanyard_discord_messages_sent,
      registry: @registry,
      labels: [],
      help: "Messages sent to discord count"
    )

    if v = initial_values["lanyard_discord_messages_sent"],
      do: Counter.inc([name: :lanyard_discord_messages_sent, registry: @registry], v)
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

  def get_all_metrics do
    metrics = [
      :lanyard_messages_outbound,
      :lanyard_messages_inbound,
      :lanyard_presence_updates,
      :lanyard_2xx_responses,
      :lanyard_4xx_responses,
      :lanyard_5xx_responses,
      :lanyard_discord_messages_sent
    ]

    for name <- metrics, into: %{} do
      value = Counter.value(name: name, registry: @registry)
      {Atom.to_string(name), value}
    end
  end
end
