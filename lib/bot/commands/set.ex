defmodule Lanyard.DiscordBot.Commands.Set do
  alias Lanyard.DiscordBot.DiscordApi

  def handle([key | value_s], payload) when length(value_s) > 1 do
    value = Enum.join(value_s, " ")

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

    :ok
  end

  def handle(_any, payload) do
    DiscordApi.send_message(
      payload["channel_id"],
      "Invalid usage. Example `set` command usage:\n`#{Application.get_env(:lanyard, :command_prefix)}set <key> <value>`"
    )

    :ok
  end
end
