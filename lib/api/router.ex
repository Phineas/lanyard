defmodule Lanyard.Api.Router do
  import Plug.Conn

  alias Lanyard.Api.Routes.Users
  alias Lanyard.Api.Util

  use Plug.Router
  plug :match
  plug :dispatch

  forward "/v1/users", to: Users

  get _ do
    Util.respond(conn, {:error, :not_found, "Route does not exist"})
  end
end
