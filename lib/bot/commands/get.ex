defmodule Lanyard.DiscordBot.Commands.Get do
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Commands.ApiKey

  def handle([key], payload) do
    if ApiKey.contains_api_key?(payload["author"]["id"], key) do
      ApiKey.generate_and_send_new(payload["channel_id"], payload["author"]["id"])
    else
      case Lanyard.KV.Interface.get(payload["author"]["id"], key) do
        {:ok, v} ->
          DiscordApi.send_message(
            payload["channel_id"],
            response_content(key, v, payload["author"]["id"])
          )

        {:error, msg} ->
          DiscordApi.send_message(payload["channel_id"], ":x: #{msg}")
      end
    end
  end

  def handle(args, payload) do
    if ApiKey.contains_api_key?(payload["author"]["id"], args) do
      ApiKey.generate_and_send_new(payload["channel_id"], payload["author"]["id"])
    else
      DiscordApi.send_message(
        payload["channel_id"],
        "Invalid usage. Example `get` command usage:\n`#{Application.get_env(:lanyard, :command_prefix)}get <key>`"
      )
    end

    :ok
  end

  @doc false
  def response_content(key, value, user_id) do
    content =
      ":white_check_mark: Key: `#{key}` | Value: ```#{String.replace(value, "`", "`\u200b")}```"

    if DiscordApi.content_within_limit?(content) do
      content
    else
      ":x: The value for `#{key}` is too long to display in Discord.\nView it at #{Application.get_env(:lanyard, :external_url)}/v1/users/#{user_id}"
    end
  end
end
