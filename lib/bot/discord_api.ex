defmodule Lanyard.DiscordBot.DiscordApi do
  @api_host "https://discord.com/api/v9"

  def send_message(channel_id, content) when is_binary(content) do
    sanitized_content =
      content
      |> String.replace("@", "@​\u200b")

    HTTPoison.post(
      "#{@api_host}/channels/#{channel_id}/messages",
      Poison.encode!(%{content: sanitized_content}),
      [
        {"Authorization", "Bot " <> Application.get_env(:lanyard, :bot_token)},
        {"Content-Type", "application/json"}
      ]
    )
  end
end
