defmodule Lanyard.Api.Routes.V1 do
  import Plug.Conn

  alias Lanyard.Api.Util
  alias Lanyard.Api.Routes.V1.Users

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    response = %{
      info:
        "Lanyard provides Discord presences as an API and WebSocket. Find out more here: https://github.com/Phineas/lanyard",
      monitored_user_count: GenRegistry.count(Lanyard.Presence)
    }

    Util.respond(conn, {:ok, response})
  end

  forward("/users", to: Users)

  match _ do
    Util.not_found(conn)
  end
end
