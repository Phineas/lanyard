defmodule Lanyard.DiscordBot.CommandRegistration do
  require Logger

  alias Lanyard.DiscordBot.CommandCache
  alias Lanyard.DiscordBot.InteractionHandler

  @api_host "https://discord.com/api/v9"

  def register(application_id) do
    definitions = InteractionHandler.command_definitions()

    result =
      :put
      |> Finch.build(
        "#{@api_host}/applications/#{application_id}/commands",
        [
          {"Authorization", "Bot " <> Application.get_env(:lanyard, :bot_token)},
          {"Content-Type", "application/json"}
        ],
        Jason.encode!(definitions)
      )
      |> Finch.request(Lanyard.Finch)

    case result do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        cache_from_body(body)
        Logger.info("Discord: Registered #{length(definitions)} slash commands")
        :ok

      {:ok, %{status: status, body: body}} ->
        Logger.error("Discord: Failed to register slash commands (status #{status}): #{body}")
        fetch(application_id)
        :error

      {:error, reason} ->
        Logger.error("Discord: Failed to register slash commands: #{inspect(reason)}")
        fetch(application_id)
        :error
    end
  end

  def fetch(application_id) do
    result =
      :get
      |> Finch.build(
        "#{@api_host}/applications/#{application_id}/commands",
        [{"Authorization", "Bot " <> Application.get_env(:lanyard, :bot_token)}]
      )
      |> Finch.request(Lanyard.Finch)

    case result do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        cache_from_body(body)
        :ok

      _ ->
        Logger.error("Discord: Failed to fetch slash commands: #{inspect(result)}")
        :error
    end
  end

  defp cache_from_body(body) do
    case Jason.decode(body) do
      {:ok, commands} when is_list(commands) ->
        CommandCache.put_many(commands)

      _ ->
        :ok
    end
  end
end
