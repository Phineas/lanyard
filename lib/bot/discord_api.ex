defmodule Lanyard.DiscordBot.DiscordApi do
  @api_host "https://discord.com/api/v9"

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
    |> track_response()
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
    |> track_response()
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
      |> track_response()

    case Jason.decode!(response.body) do
      %{"id" => id} ->
        id

      _ ->
        :ok
    end
  end

  defp track_response({:ok, %Finch.Response{status: status}} = result) do
    Lanyard.Metrics.Collector.inc(:counter, :lanyard_discord_api_requests_total, [
      Lanyard.Metrics.Collector.status_class(status)
    ])

    result
  end

  defp track_response({:error, _reason} = result) do
    Lanyard.Metrics.Collector.inc(:counter, :lanyard_discord_api_requests_total, ["error"])

    result
  end
end
