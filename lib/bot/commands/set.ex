defmodule Lanyard.DiscordBot.Commands.Set do
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.Connectivity.Redis

  def handle([key, value], payload) do
    cond do
      String.length(key) > 255 ->
        DiscordApi.send_message(payload["channel_id"], "`key` must be 255 characters or less")

      not String.match?(key, ~r/^[a-zA-Z0-9_]*$/) ->
        DiscordApi.send_message(
          payload["channel_id"],
          "`key` must be alphanumeric (a-zA-Z0-9_)"
        )

      true ->
        Lanyard.KV.Interface.set(payload["author"]["id"], key, value)

        DiscordApi.send_message(
          payload["channel_id"],
          ":white_check_mark: Success! `#{key}` was set to: ```#{value}```"
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
