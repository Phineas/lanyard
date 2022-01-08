defmodule Lanyard.DiscordBot.Commands.Del do
  alias Lanyard.DiscordBot.DiscordApi

  def handle([key], payload) do
    Lanyard.KV.Interface.del(payload["author"]["id"], key)

    DiscordApi.send_message(payload["channel_id"], ":white_check_mark: Deleted key: `#{key}`")
  end

  def handle(_, payload) do
    DiscordApi.send_message(
      payload["channel_id"],
      "Invalid usage. Example `del` command usage:\n#{Application.get_env(:lanyard, :command_prefix)}del <key>`"
    )

    :ok
  end
end
