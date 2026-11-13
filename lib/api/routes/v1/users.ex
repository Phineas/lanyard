defmodule Lanyard.Api.Routes.V1.Users do
  alias Lanyard.Api.Util
  alias Lanyard.Presence
  alias Lanyard.Connectivity.Redis

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/@me" do
    key = Util.authorization_header(conn)

    if key == nil do
      Util.no_permission(conn)
    else
      case Redis.get("api_key:#{key}") do
        user_id when is_binary(user_id) ->
          Util.respond(conn, Presence.get_pretty_presence(user_id))

        _ ->
          Util.no_permission(conn)
      end
    end
  end

  get "/:id" do
    %Plug.Conn{params: %{"id" => user_id}} = conn

    Util.respond(conn, Presence.get_pretty_presence(user_id))
  end

  patch "/:id/kv" do
    with {:ok, user_id} <- validate_resource_access(conn),
         {:ok, body, conn} <- read_kv_body(conn) do
      try do
        {:ok, parsed} = Jason.decode(body)

        case Lanyard.KV.Interface.multiset(user_id, parsed) do
          {:ok} ->
            Util.respond(conn, {:ok})

          {:error, reason} ->
            Util.respond(conn, {:error, :kv_validation_failed, reason})
        end
      rescue
        _e ->
          Util.respond(conn, {:error, :invalid_kv_value, "body must be an object"})
      end
    else
      :no_permission -> Util.no_permission(conn)
      {:error, conn, status, code, message} -> Util.respond(conn, {:error, status, code, message})
    end
  end

  put "/:id/kv/:field" do
    %Plug.Conn{params: %{"field" => field}} = conn

    with {:ok, user_id} <- validate_resource_access(conn),
         {:ok, put_body, conn} <- read_kv_body(conn) do
      case Lanyard.KV.Interface.set(String.to_integer(user_id), field, put_body) do
        {:ok, _v} ->
          Util.respond(conn, {:ok})

        {:error, reason} ->
          Util.respond(conn, {:error, :kv_validation_failed, reason})
      end
    else
      :no_permission -> Util.no_permission(conn)
      {:error, conn, status, code, message} -> Util.respond(conn, {:error, status, code, message})
    end
  end

  delete "/:id/kv/:field" do
    %Plug.Conn{params: %{"field" => field}} = conn

    case validate_resource_access(conn) do
      {:ok, user_id} ->
        Lanyard.KV.Interface.del(String.to_integer(user_id), field)
        Util.respond(conn, {:ok})

      :no_permission ->
        Util.no_permission(conn)
    end
  end

  match _ do
    Util.not_found(conn)
  end

  # Called after authentication. Answers 413 instead of crashing on a body that does not fit in
  # one read (Plug.Conn.read_body/2 defaults to 8 MB).
  defp read_kv_body(conn) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} -> {:ok, body, conn}
      {:more, _partial, conn} -> {:error, conn, 413, :body_too_large, "request body is too large"}
      {:error, _reason} -> {:error, conn, 400, :invalid_body, "could not read the request body"}
    end
  end

  defp validate_resource_access(conn) do
    %Plug.Conn{params: %{"id" => id}} = conn
    key = Util.authorization_header(conn)

    if key == nil do
      :no_permission
    else
      case Redis.get("api_key:#{key}") do
        resolved_id when is_binary(resolved_id) and (id == "@me" or id == resolved_id) ->
          if Presence.monitored?(resolved_id), do: {:ok, resolved_id}, else: :no_permission

        _ ->
          :no_permission
      end
    end
  end
end
