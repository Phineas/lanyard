defmodule Lanyard.Api.Util do
  import Plug.Conn

  @spec redirect(Plug.Conn.t(), binary) :: Plug.Conn.t()
  def redirect(conn, url) do
    conn
    |> put_resp_header("location", url)
    |> send_resp(:found, url)
  end

  @spec respond(Plug.Conn.t(), {:ok, any}) :: Plug.Conn.t()
  def respond(conn, {:ok, data}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(%{success: true, data: data}))
  end

  @spec respond(Plug.Conn.t(), {:error, atom, binary}) :: Plug.Conn.t()
  def respond(conn, {:error, code, reason}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      404,
      Poison.encode!(%{
        success: false,
        error: %{
          code: Atom.to_string(code),
          message: reason
        }
      })
    )
  end

  @spec not_found(Plug.Conn.t()) :: Plug.Conn.t()
  def not_found(conn) do
    respond(conn, {:error, :not_found, "Route does not exist"})
  end
end
