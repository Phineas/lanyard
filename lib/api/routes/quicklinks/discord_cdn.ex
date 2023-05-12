defmodule Lanyard.Api.Quicklinks.DiscordCdn do
  @moduledoc """
  A module for proxying Discord CDN images.
  """

  alias Lanyard.Api.Util
  import Plug.Conn

  @discord_cdn "https://cdn.discordapp.com"

  @spec proxy_image(Plug.Conn.t()) :: Plug.Conn.t()
  def proxy_image(conn) do
    [user_id, file_type] =
      conn.request_path
      |> String.split("/")
      |> Enum.at(1)
      |> String.split(".")
    
    presence = Lanyard.Presence.get_pretty_presence(user_id)

    case presence do
      {:ok, %{discord_user: %{avatar: avatar}}} when is_binary(avatar) ->
        url = construct_avatar_url(user_id, avatar, file_type)
        get_proxied_image(conn, url)

      {:ok, _} ->
        Util.respond(conn, :not_found)

      _ ->
        Util.respond(conn, presence)
    end
  end

  @spec get_proxied_image(Plug.Conn.t(), String.t()) :: HTTPoison.Response.t()
  defp get_proxied_image(conn, url) do
    HTTPoison.get(url)
    |> handle_image_response(conn)
  end

  @spec handle_image_response(Plug.Conn.t(),
