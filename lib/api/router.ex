defmodule Lanyard.Api.Router do
  import Plug.Conn

  alias Lanyard.Api.Routes.Users

  use Plug.Router
  plug :match
  plug :dispatch

  forward "/v1/users", to: Users
end
