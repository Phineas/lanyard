defmodule Lanyard.DiscordBot.DiscordApi do
  @api_host "https://discord.com/api/v9"
  @max_content_length 2_000

  def send_message(channel_id, content) when is_binary(content) do
    Lanyard.Metrics.Collector.inc(:counter, :lanyard_discord_messages_sent)

    sanitized_content =
      content
      |> sanitize_content()

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

  @doc false
  def content_within_limit?(content) when is_binary(content) do
    content
    |> sanitize_content()
    |> String.length()
    |> Kernel.<=(@max_content_length)
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

  defp sanitize_content(content) do
    String.replace(content, "@", "@​\u200b")
  end
end
