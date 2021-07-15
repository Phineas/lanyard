defmodule Lanyard.Api.Routes.V1.Users do
  import Plug.Conn

  alias Lanyard.Api.Util
  alias Lanyard.Presence

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/:id" do
    %Plug.Conn{params: %{"id" => user_id}} = conn

    Util.respond(conn, Presence.get_pretty_presence(user_id))

    # case Presence.get_presence(user_id) do
    #   {:ok, raw_data} ->
    #     Util.respond(conn, Presence.build_pretty_presence(raw_data))

    #   other ->
    #     Util.respond(conn, other)
    # end
  end

  match _ do
    Util.not_found(conn)
  end
end
