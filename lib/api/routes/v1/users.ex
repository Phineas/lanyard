defmodule Lanyard.Api.Routes.V1.Users do
  import Plug.Conn

  alias Lanyard.Api.Util
  alias Lanyard.Presence
  alias Lanyard.Connectivity.Redis

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/@me" do
    key = conn |> Plug.Conn.get_req_header("authorization")

    case Redis.get("api_key:#{key}") do
      user_id when is_binary(user_id) ->
        Util.respond(conn, Presence.get_pretty_presence(user_id))

      _ ->
        Util.respond(conn, {:error, :invalid_api_key, "Invalid api key"})
    end
  end

  get "/:id" do
    %Plug.Conn{params: %{"id" => user_id}} = conn

    Util.respond(conn, Presence.get_pretty_presence(user_id))
  end

  patch "/:id/kv" do
    %Plug.Conn{params: %{"id" => user_id}} = conn

    {:ok, body, _conn} = Plug.Conn.read_body(conn)

    case validate_resource_access(conn) do
      :ok ->
        try do
          {:ok, parsed} = Poison.decode(body)

          Enum.each(parsed, fn {k, v} ->
            with {:error, _reason} = err <- Lanyard.KV.Interface.validate_pair({k, v}) do
              throw(err)
            end
          end)

          Lanyard.KV.Interface.multiset(user_id, parsed)

          Util.respond(conn, {:ok})
        rescue
          _e ->
            Util.respond(conn, {:error, :invalid_kv_value, "body must be an object"})
        catch
          {:error, reason} -> Util.respond(conn, {:error, :kv_validation_failed, reason})
        end

      :no_permission ->
        Util.no_permission(conn)
    end
  end

  put "/:id/kv/:field" do
    %Plug.Conn{params: %{"id" => user_id, "field" => field}} = conn

    {:ok, put_body, _conn} = Plug.Conn.read_body(conn)

    case validate_resource_access(conn) do
      :ok ->
        case Lanyard.KV.Interface.set(String.to_integer(user_id), field, put_body) do
          {:ok, _v} ->
            Util.respond(conn, {:ok})

          {:error, reason} ->
            Util.respond(conn, {:error, :kv_validation_failed, reason})
        end

      :no_permission ->
        Util.no_permission(conn)
    end
  end

  delete "/:id/kv/:field" do
    %Plug.Conn{params: %{"id" => user_id, "field" => field}} = conn

    case validate_resource_access(conn) do
      :ok ->
        Lanyard.KV.Interface.del(String.to_integer(user_id), field)
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
