defmodule Lanyard.DiscordBot.Commands.Set do
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Commands.ApiKey

  def handle([key | value_s], payload) when length(value_s) > 0 do
    value = Enum.join(value_s, " ")

    case ApiKey.validate_api_key(payload["author"]["id"], key) do
      {true} ->
        DiscordApi.send_message(
          payload["channel_id"],
          ":x: Whoops, you just posted your API key, this is meant to stay private, regenerating this for you, check your DM"
        )

        ApiKey.generate_and_send_new(payload["author"]["id"])

      {false} ->
        case Lanyard.KV.Interface.set(payload["author"]["id"], key, value) do
          {:error, reason} ->
            DiscordApi.send_message(
              payload["channel_id"],
              ":x: #{reason}"
            )

          _ ->
            DiscordApi.send_message(
              payload["channel_id"],
              ":white_check_mark: `#{key}` was set. View it with `#{Application.get_env(:lanyard, :command_prefix)}get #{key}` or go to https://api.lanyard.rest/v1/users/#{payload["author"]["id"]}"
            )
        end
    end

    :ok
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
          "Invalid usage. Example `set` command usage:\n`#{Application.get_env(:lanyard, :command_prefix)}set <key> <value>`"
        )

      _ ->
        :ok
    end

    :ok
  end
end
