defmodule Lanyard.DiscordBot.CommandHandler do
  @command_map %{
    "get" => Lanyard.DiscordBot.Commands.Get,
    "set" => Lanyard.DiscordBot.Commands.Set,
    "del" => Lanyard.DiscordBot.Commands.Del,
    "apikey" => Lanyard.DiscordBot.Commands.ApiKey,
    "kv" => Lanyard.DiscordBot.Commands.KV
  }

  def handle_message(payload) do
    case payload.data do
      # Don't handle messages from other bots
      %{"author" => %{"bot" => true}} ->
        :ok

      %{"content" => content} ->
        if String.starts_with?(content, Application.get_env(:lanyard, :command_prefix)) do
          [attempted_command | args] =
            content
            |> String.to_charlist()
            |> tl()
            |> to_string()
            |> String.split(" ")

          unless @command_map[attempted_command] == nil do
            @command_map[attempted_command].handle(args, payload.data)
          end
        end

      _ ->
        :ok
    end
  end

  def handle_command(_unknown_command, _args), do: :ok
end
