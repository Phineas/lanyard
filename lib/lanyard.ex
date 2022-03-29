defmodule Lanyard do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    :ets.new(:cached_presences, [:named_table, :set, :public])
    :ets.new(:global_subscribers, [:named_table, :set, :public])
    :ets.new(:analytics, [:named_table, :set, :public])

    children = [
      {GenRegistry, worker_module: Lanyard.Presence},
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Lanyard.Router,
        options: [
          port: Application.get_env(:lanyard, :http_port),
          dispatch: dispatch(),
          protocol_options: [idle_timeout: :infinity]
        ]
      ),
      {Lanyard.DiscordBot, %{token: Application.get_env(:lanyard, :bot_token)}},
      {Lanyard.Connectivity.Redis, []}
    ]

    opts = [strategy: :one_for_one, name: Lanyard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/socket", Lanyard.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {Lanyard.Api.Router, []}}
       ]}
    ]
  end
end
