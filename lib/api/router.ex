defmodule Lanyard.Api.Router do
  import Plug.Conn

  alias Lanyard.Api.Routes.V1
  alias Lanyard.Api.Routes.Discord
  alias Lanyard.Api.Util

  use Plug.Router

  plug(Corsica,
    origins: "*",
    max_age: 600
  )

  plug(:match)
  plug(:dispatch)

  forward("/v1", to: V1)
  forward("/discord", to: Discord)

  options _ do
    conn
    |> send_resp(204, "")
  end

  match _ do
    Util.not_found(conn)
  end
end
