defmodule Lanyard.Api.Router do
  import Plug.Conn

  alias Lanyard.Api.Routes.V1
  alias Lanyard.Api.Routes.Discord
  alias Lanyard.Api.Util
  alias Lanyard.Api.Quicklinks

  use Plug.Router

  @supported_quicktypes ["png", "gif", "webp", "jpg", "jpeg"]

  plug(Corsica,
    origins: "*",
    max_age: 600,
    allow_methods: :all,
    allow_headers: :all
  )

  plug(:match)
  plug(:dispatch)

  forward("/v1", to: V1)
  forward("/discord", to: Discord)

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
