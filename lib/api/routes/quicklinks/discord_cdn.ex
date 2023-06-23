defmodule Lanyard.Api.Quicklinks.DiscordCdn do
  alias Lanyard.Api.Util

  import Plug.Conn
  import Bitwise

  @discord_cdn "https://cdn.discordapp.com"

  def proxy_image(conn) do
    [user_id, file_type] =
      conn.request_path
      |> String.split("/")
      |> Enum.at(1)
      |> String.split(".")

    presence = Lanyard.Presence.get_pretty_presence(user_id)

    case presence do
      {:ok, p} ->
        {:ok, %Finch.Response{body: b, headers: h, status: status_code}} =
          get_proxied_avatar(
            user_id,
            p.discord_user.avatar,
            p.discord_user.discriminator,
            file_type
          )

        conn
        |> merge_resp_headers(h)
        |> delete_resp_header("content-length")
        |> send_resp(status_code, b)

      error ->
        Util.respond(conn, error)
    end
  end

  defp get_proxied_avatar(id, avatar, _discriminator, file_type) when is_binary(avatar) do
    constructed_cdn_url = "#{@discord_cdn}/avatars/#{id}/#{avatar}.#{file_type}?size=1024"

    :get
    |> Finch.build(constructed_cdn_url)
    |> Finch.request(Lanyard.Finch)
  end

  defp get_proxied_avatar(id, avatar, "0", _file_type) when is_nil(avatar) do
    mod = Integer.mod(String.to_integer(id) >>> 22, 6)

    :get
    |> Finch.build("#{@discord_cdn}/embed/avatars/#{mod}.png")
    |> Finch.request(Lanyard.Finch)
  end

  defp get_proxied_avatar(_id, avatar, discriminator, _file_type) when is_nil(avatar) do
    mod = Integer.mod(String.to_integer(discriminator), 5)

    :get
    |> Finch.build("#{@discord_cdn}/embed/avatars/#{mod}.png")
    |> Finch.request(Lanyard.Finch)
  end
end
