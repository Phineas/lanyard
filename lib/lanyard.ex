defmodule Lanyard do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      {GenRegistry, worker_module: Lanyard.Presence},
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Lanyard.Router,
        options: [port: 4001, dispatch: dispatch(), protocol_options: [idle_timeout: :infinity]]
      ),
      {Lanyard.DiscordBot, %{token: Application.get_env(:lanyard, :bot_token)}}
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
