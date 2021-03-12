defmodule Lanyard.Api.Router do
  import Plug.Conn

  alias Lanyard.Api.Routes.Users
  alias Lanyard.Api.Util

  use Plug.Router
  plug Corsica, origins: "*",
    max_age: 600
  plug :match
  plug :dispatch

  forward "/v1/users", to: Users

  options _ do
    conn
    |> send_resp(204, "")
  end

  get _ do
    Util.respond(conn, {:error, :not_found, "Route does not exist"})
  end
end
