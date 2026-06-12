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

  def respond_to_interaction(interaction_id, interaction_token, content, opts \\ [])

  def respond_to_interaction(interaction_id, interaction_token, content, opts)
      when is_binary(content) do
    Lanyard.Metrics.Collector.inc(:counter, :lanyard_discord_messages_sent)

    sanitized_content =
      content
      |> String.replace("@", "@​​")

    data = %{content: sanitized_content}
    data = if opts[:ephemeral], do: Map.put(data, :flags, 64), else: data

    :post
    |> Finch.build(
      "#{@api_host}/interactions/#{interaction_id}/#{interaction_token}/callback",
      [{"Content-Type", "application/json"}],
      Jason.encode!(%{type: 4, data: data})
    )
    |> Finch.request(Lanyard.Finch)
  end

  def respond_to_interaction(interaction_id, interaction_token, %{} = embed, opts) do
    Lanyard.Metrics.Collector.inc(:counter, :lanyard_discord_messages_sent)

    data = %{embeds: [embed]}
    data = if opts[:ephemeral], do: Map.put(data, :flags, 64), else: data

    :post
    |> Finch.build(
      "#{@api_host}/interactions/#{interaction_id}/#{interaction_token}/callback",
      [{"Content-Type", "application/json"}],
      Jason.encode!(%{type: 4, data: data})
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
