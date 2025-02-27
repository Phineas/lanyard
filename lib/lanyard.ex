defmodule Lanyard do
  require Logger
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    :ets.new(:cached_presences, [:named_table, :set, :public])
    :ets.new(:global_subscribers, [:named_table, :set, :public])

    children = [
      {Finch, name: Lanyard.Finch},
      {GenRegistry, worker_module: Lanyard.Presence},
      {Lanyard.Metrics, :normal},
      {Lanyard.Connectivity.Redis, []},
      {Lanyard.DiscordBot, %{token: Application.get_env(:lanyard, :bot_token)}},
      {Bandit,
       plug: Lanyard.Api.Router, scheme: :http, port: Application.get_env(:lanyard, :http_port)}
    ]

    opts = [strategy: :one_for_one, name: Lanyard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def is_idempotent?() do
    case System.get_env("BOT_IDEMPOTENCY_ENV_KEY") do
      nil ->
        true

      "" ->
        true

      key ->
        case String.split(key, "=", parts: 2, trim: true) do
          [env_key, expected_value] ->
            System.get_env(env_key) == expected_value

          _ ->
            false
        end
    end
  end
end
