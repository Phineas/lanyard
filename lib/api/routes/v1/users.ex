defmodule Lanyard.Api.Routes.V1.Users do
  import Plug.Conn

  alias Lanyard.Api.Util
  alias Lanyard.Presence
  alias Lanyard.Connectivity.Redis

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/:id" do
    %Plug.Conn{params: %{"id" => user_id}} = conn

    Util.respond(conn, Presence.get_pretty_presence(user_id))
  end

  patch "/:id/kv" do
    case validate_resource_access(conn) do
      :ok ->
        IO.inspect("Yo")

      :no_permission ->
        Util.no_permission(conn)
    end
  end

  put "/:id/kv/:field" do
    %Plug.Conn{params: %{"id" => user_id, "field" => field}} = conn

    {:ok, put_body, _conn} = Plug.Conn.read_body(conn)

    case validate_resource_access(conn) do
      :ok ->
        Lanyard.KV.Interface.set(user_id, field, put_body)

        Util.respond(conn, {:ok})

      :no_permission ->
        Util.no_permission(conn)
    end
  end

  delete "/:id/kv/:field" do
    %Plug.Conn{params: %{"id" => user_id, "field" => field}} = conn

    case validate_resource_access(conn) do
      :ok ->
        Lanyard.KV.Interface.del(user_id, field)
        Util.respond(conn, {:ok})

      :no_permission ->
        Util.no_permission(conn)
    end
  end

  match _ do
    Util.not_found(conn)
  end

  defp validate_resource_access(conn) do
    %Plug.Conn{params: %{"id" => user_id}} = conn
    key = conn |> Plug.Conn.get_req_header("authorization")

    case Redis.get("api_key:#{key}") do
      ^user_id ->
        :ok

      _ ->
        :no_permission
    end
  end
end
