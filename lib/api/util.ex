defmodule Lanyard.Api.Util do
  import Plug.Conn

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
    |> send_resp(404, Poison.encode!(%{success: false, error: %{
      code: Atom.to_string(code),
      message: reason
    }}))
  end
end
