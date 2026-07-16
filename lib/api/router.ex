defmodule Lanyard.Api.Router do
  import Plug.Conn

  alias Lanyard.Api.Routes.V1
  alias Lanyard.Api.Routes.Discord
  alias Lanyard.Api.Routes.Metrics
  alias Lanyard.Api.Util
  alias Lanyard.Api.Quicklinks

  use Plug.Router
  use Plug.ErrorHandler

  @supported_quicktypes ["png", "gif", "webp", "jpg", "jpeg"]

  plug(Corsica,
    origins: "*",
    max_age: 600,
    allow_methods: :all,
    allow_headers: :all
  )

  plug(:track_request)
  plug(:match)
  plug(:dispatch)

  def track_request(conn, _opts) do
    start = System.monotonic_time()

    register_before_send(conn, fn conn ->
      elapsed =
        System.convert_time_unit(System.monotonic_time() - start, :native, :microsecond) /
          1_000_000

      Lanyard.Metrics.Collector.observe(
        :histogram,
        :lanyard_http_request_duration_seconds,
        elapsed
      )

      stat =
        cond do
          is_nil(conn.status) ->
            nil

          conn.status >= 200 && conn.status < 300 ->
            :lanyard_2xx_responses

          conn.status >= 300 && conn.status < 400 ->
            :lanyard_3xx_responses

          conn.status >= 400 && conn.status < 500 ->
            :lanyard_4xx_responses

          conn.status >= 500 ->
            :lanyard_5xx_responses

          true ->
            nil
        end

      if stat, do: Lanyard.Metrics.Collector.inc(:counter, stat)

      conn
    end)
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, _error) do
    Lanyard.Metrics.Collector.inc(:counter, :lanyard_http_exceptions_total)

    send_resp(conn, conn.status, "Internal Server Error")
  end

  get "/" do
    response = %{
      info:
        "Lanyard provides Discord presences as an API and WebSocket. Find out more here: https://github.com/Phineas/lanyard",
      monitored_user_count: GenRegistry.count(Lanyard.Presence),
      discord_invite: "https://discord.gg/lanyard"
    }

    Util.respond(conn, {:ok, response})
  end

  get "/socket" do
    %Plug.Conn{query_params: params} = fetch_query_params(conn)

    try do
      conn
      |> WebSockAdapter.upgrade(Lanyard.SocketHandler, params, timeout: 60_000)
      |> halt()
    rescue
      WebSockAdapter.UpgradeError ->
        Lanyard.Metrics.Collector.inc(:counter, :lanyard_socket_closes_total, ["upgrade_failed"])

        conn
        |> Util.respond({:error, 400, :upgrade_failed, "Request failed to upgrade"})
        |> halt()

      # i would image this is effectively useless as only the Upgrade could throw
      other ->
        reraise other, __STACKTRACE__
    end
  end

  forward("/v1", to: V1)
  forward("/discord", to: Discord)
  forward("/metrics", to: Metrics)

  get _ do
    quicktype = String.split(conn.request_path, ".") |> Enum.at(-1)

    cond do
      Enum.member?(@supported_quicktypes, quicktype) ->
        Quicklinks.DiscordCdn.proxy_image(conn)

      true ->
        Util.not_found(conn)
    end
  end

  options _ do
    conn
    |> send_resp(204, "")
  end

  match _ do
    Util.not_found(conn)
  end
end
