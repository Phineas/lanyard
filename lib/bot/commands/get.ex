defmodule Lanyard.DiscordBot.Commands.Get do
  alias Lanyard.DiscordBot.DiscordApi

  def handle([key], payload) do
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

  def handle(_, payload) do
    DiscordApi.send_message(
      payload["channel_id"],
      "Invalid usage. Example `del` command usage:\n`.del <key>`"
    )

    :ok
  end
end
