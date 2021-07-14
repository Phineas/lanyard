defmodule Lanyard.Api.Routes.V1 do
  import Plug.Conn

  alias Lanyard.Api.Util
  alias Lanyard.Api.Routes.V1.Users

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  forward("/users", to: Users)

  match _ do
    Util.not_found(conn)
  end
end
