defmodule Lanyard.DiscordBot.CommandHandler do
  alias Lanyard.DiscordBot.CommandCache
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Embed

  @command_map %{
    "get" => Lanyard.DiscordBot.Commands.Get,
    "set" => Lanyard.DiscordBot.Commands.Set,
    "del" => Lanyard.DiscordBot.Commands.Del,
    "apikey" => Lanyard.DiscordBot.Commands.ApiKey,
    "kv" => Lanyard.DiscordBot.Commands.KV,
    "help" => Lanyard.DiscordBot.Commands.KV,
    "about" => Lanyard.DiscordBot.Commands.About
  }

  def handle_message(payload) do
    case payload.data do
      %{"author" => %{"bot" => true}} ->
        :ok

      %{"content" => content} = data ->
        prefix = Application.get_env(:lanyard, :command_prefix)

        cond do
          String.starts_with?(content, prefix) -> handle_prefix_command(content, data)
          dm?(data) -> send_dm_hint(data["channel_id"])
          true -> :ok
        end

      %{"channel_id" => channel_id} = data ->
        if dm?(data), do: send_dm_hint(channel_id)

      _ ->
        :ok
    end
  end

  def handle_command(_unknown_command, _args), do: :ok

  defp handle_prefix_command(content, data) do
    [attempted_command | args] =
      content
      |> String.to_charlist()
      |> tl()
      |> to_string()
      |> String.split(" ")

    unless @command_map[attempted_command] == nil do
      @command_map[attempted_command].handle(args, data)
    end
  end

  defp dm?(data), do: is_nil(data["guild_id"])

  defp send_dm_hint(channel_id) do
    embed =
      Embed.info(%{
        title: ":wave: Hi! I'm Lanyard",
        description:
          "Looking for your API key? Use #{CommandCache.mention("apikey")} — the response is private to you.\n\n**Other slash commands:**\n#{CommandCache.mention("kv")} — view your K/V keys\n#{CommandCache.mention("get")} — get a value\n#{CommandCache.mention("set")} — set a key\n#{CommandCache.mention("del")} — delete a key\n#{CommandCache.mention("about")} — privacy policy & terms of service",
        footer: %{text: "Type / in any channel to see my commands"}
      })

    DiscordApi.send_message(channel_id, embed)
  end
end
