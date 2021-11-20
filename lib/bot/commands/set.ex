defmodule Lanyard.DiscordBot.Commands.Set do
  alias Lanyard.DiscordBot.DiscordApi

  def handle([key, value], payload) do
    case Lanyard.KV.Interface.set(payload["author"]["id"], key, value) do
      {:error, reason} ->
        DiscordApi.send_message(
          payload["channel_id"],
          ":x: #{reason}"
        )

      _ ->
        DiscordApi.send_message(
          payload["channel_id"],
          ":white_check_mark: `#{key}` was set. View it with `.get #{key}` or go to https://api.lanyard.rest/v1/users/#{payload["author"]["id"]}"
        )
    end

    :ok
  end

  def handle(_any, payload) do
    DiscordApi.send_message(
      payload["channel_id"],
      "Invalid usage. Example `set` command usage:\n`.set <key> <value>`"
    )

    :ok
  end
end
