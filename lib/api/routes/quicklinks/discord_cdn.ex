defmodule Lanyard.Api.Quicklinks.DiscordCdn do
  alias Lanyard.Api.Util

  import Plug.Conn
  import Bitwise

  @discord_cdn "https://cdn.discordapp.com"

  def proxy_image(conn) do
    segment =
      conn.request_path
      |> String.split("/")
      |> Enum.at(1)

    case String.split(segment, ".") do
      [user_id, file_type] -> do_proxy_image(conn, user_id, file_type)
      _ -> Util.not_found(conn)
    end
  end

  defp do_proxy_image(conn, user_id, file_type) do
    presence = Lanyard.Presence.get_pretty_presence(user_id)

    case presence do
      {:ok, p} ->
        case get_proxied_avatar(
               user_id,
               p.discord_user["avatar"],
               p.discord_user["discriminator"],
               file_type
             ) do
          {:ok, %Finch.Response{body: b, headers: h, status: status_code}} ->
            Lanyard.Metrics.Collector.inc(:counter, :lanyard_cdn_proxy_requests_total, [
              Lanyard.Metrics.Collector.status_class(status_code)
            ])

            conn
            |> merge_resp_headers(h)
            |> delete_resp_header("content-length")
            |> send_resp(status_code, b)

          {:error, _reason} ->
            Lanyard.Metrics.Collector.inc(:counter, :lanyard_cdn_proxy_requests_total, ["error"])

            Util.respond(
              conn,
              {:error, 502, :upstream_error, "Failed to fetch avatar from Discord CDN"}
            )
        end

      error ->
        Util.respond(conn, error)
    end
  end

  defp get_proxied_avatar(id, avatar, _discriminator, file_type) when is_binary(avatar) do
    file_type =
      if !String.starts_with?(avatar, "a_") && file_type == "gif" do
        "jpg"
      else
        file_type
      end

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