defmodule Lanyard.DiscordBot.DiscordApi do
  @api_host "https://discord.com/api/v10"

  def fetch_user_profile(user_id) do
    case :get
         |> Finch.build(
           "#{@api_host}/users/#{user_id}/profile",
           [
             {"Authorization", "Bot " <> Application.get_env(:lanyard, :bot_token)}
           ],
           nil
         )
         |> Finch.request(Lanyard.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          _ -> {:error, :invalid_json}
        end

      {:ok, %Finch.Response{status: status}} ->
        {:error, :http_error, status}

      {:error, reason} ->
        {:error, :request_failed, reason}
    end
  end

  def send_message(channel_id, content) when is_binary(content) do
    Lanyard.Metrics.Collector.inc(:counter, :lanyard_discord_messages_sent)

    sanitized_content =
      content
      |> String.replace("@", "@​\u200b")

    :post
    |> Finch.build(
      "#{@api_host}/channels/#{channel_id}/messages",
      [
        {"Authorization", "Bot " <> Application.get_env(:lanyard, :bot_token)},
        {"Content-Type", "application/json"}
      ],
      Jason.encode!(%{content: sanitized_content})
    )
    |> Finch.request(Lanyard.Finch)
  end

  def send_message(channel_id, %{} = embed) do
    Lanyard.Metrics.Collector.inc(:counter, :lanyard_discord_messages_sent)

    :post
    |> Finch.build(
      "#{@api_host}/channels/#{channel_id}/messages",
      [
        {"Authorization", "Bot " <> Application.get_env(:lanyard, :bot_token)},
        {"Content-Type", "application/json"}
      ],
      Jason.encode!(%{embeds: [embed]})
    )
    |> Finch.request(Lanyard.Finch)
  end

  def create_dm(recipient) do
    {:ok, response} =
      :post
      |> Finch.build(
        "#{@api_host}/users/@me/channels",
        [
          {"Authorization", "Bot " <> Application.get_env(:lanyard, :bot_token)},
          {"Content-Type", "application/json"}
        ],
        Jason.encode!(%{recipient_id: recipient})
      )
      |> Finch.request(Lanyard.Finch)

    case Jason.decode!(response.body) do
      %{"id" => id} ->
        id

      _ ->
        :ok
    end
  end
end
