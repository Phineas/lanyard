defmodule Lanyard.DiscordBot.Commands.Del do
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Commands.ApiKey

  def handle([key], payload) do
    if ApiKey.contains_api_key?(payload["author"]["id"], key) do
      ApiKey.generate_and_send_new(payload["channel_id"], payload["author"]["id"])
    else
      Lanyard.KV.Interface.del(payload["author"]["id"], key)

      DiscordApi.send_message(payload["channel_id"], ":white_check_mark: Deleted key: `#{key}`")
    end
  end

  def handle(args, payload) do
    if ApiKey.contains_api_key?(payload["author"]["id"], args) do
      ApiKey.generate_and_send_new(payload["channel_id"], payload["author"]["id"])
    else
      DiscordApi.send_message(
        payload["channel_id"],
        "Invalid usage. Example `del` command usage:\n`#{Application.get_env(:lanyard, :command_prefix)}del <key>`"
      )
    end

    :ok
  end
end
