defmodule Lanyard do
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
end
