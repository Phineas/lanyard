defmodule Lanyard.DiscordBot.Commands.Get do
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Commands.ApiKey

  def handle([key], payload) do
    case ApiKey.validate_api_key(payload["author"]["id"], key) do
      {true} ->
        DiscordApi.send_message(
          payload["channel_id"],
          ":x: Whoops, you just posted your API key, this is meant to stay private, regenerating this for you, check your DM"
        )

        ApiKey.generate_and_send_new(payload["author"]["id"])

      {false} ->
        case Lanyard.KV.Interface.get(payload["author"]["id"], key) do
          {:ok, v} ->
            DiscordApi.send_message(
              payload["channel_id"],
              ":white_check_mark: Key: `#{key}` | Value: ```#{String.replace(v, "`", "`\u200b")}```"
            )

          {:error, msg} ->
            DiscordApi.send_message(payload["channel_id"], ":x: #{msg}")
        end
    end
  end

  def handle(any, payload) do
    case ApiKey.validate_api_key(payload["author"]["id"], any) do
      [{true}] ->
        DiscordApi.send_message(
          payload["channel_id"],
          ":x: Whoops, you just posted your API key, this is meant to stay private, regenerating this for you, check your DM"
        )

        ApiKey.generate_and_send_new(payload["author"]["id"])

      [{false}] ->
        DiscordApi.send_message(
          payload["channel_id"],
          "Invalid usage. Example `get` command usage:\n`#{Application.get_env(:lanyard, :command_prefix)}get <key>`"
        )
    end

    :ok
  end
end
