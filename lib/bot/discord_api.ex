defmodule Lanyard.DiscordBot.DiscordApi do
  @api_host "https://discord.com/api/v9"

  def send_message(channel_id, content) when is_binary(content) do
    HTTPoison.post(
      "#{@api_host}/channels/#{channel_id}/messages",
      Poison.encode!(%{content: content}),
      [
        {"Authorization", "Bot " <> Application.get_env(:lanyard, :bot_token)},
        {"Content-Type", "application/json"}
      ]
    )
  end
end
