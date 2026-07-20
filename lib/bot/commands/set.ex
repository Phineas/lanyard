defmodule Lanyard.DiscordBot.Commands.Set do
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Commands.ApiKey

  def handle([key | value_s], payload) when length(value_s) > 0 do
    value = Enum.join(value_s, " ")

    if ApiKey.contains_api_key?(payload["author"]["id"], key) do
      ApiKey.generate_and_send_new(payload["channel_id"], payload["author"]["id"])
    else
      case Lanyard.KV.Interface.set(payload["author"]["id"], key, value) do
        {:error, reason} ->
          DiscordApi.send_message(
            payload["channel_id"],
            ":x: #{reason}"
          )

        _ ->
          DiscordApi.send_message(
            payload["channel_id"],
            ":white_check_mark: `#{key}` was set. View it with `#{Application.get_env(:lanyard, :command_prefix)}get #{key}` or go to #{Application.get_env(:lanyard, :external_url)}/v1/users/#{payload["author"]["id"]}"
          )
      end
    end

    :ok
  end

  def handle(args, payload) do
    if ApiKey.contains_api_key?(payload["author"]["id"], args) do
      ApiKey.generate_and_send_new(payload["channel_id"], payload["author"]["id"])
    else
      DiscordApi.send_message(
        payload["channel_id"],
        "Invalid usage. Example `set` command usage:\n`#{Application.get_env(:lanyard, :command_prefix)}set <key> <value>`"
      )
    end

    :ok
  end
end
