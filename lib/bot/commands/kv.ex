defmodule Lanyard.DiscordBot.Commands.KV do
  alias Lanyard.DiscordBot.CommandCache
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Embed
  alias Lanyard.DiscordBot.InteractionHandler

  def definition do
    %{
      name: "kv",
      description: "List the keys in your Lanyard K/V store"
    }
  end

  def handle(_, payload) do
    user_id = payload["author"]["id"]
    channel_id = payload["channel_id"]

    embed =
      if dm?(payload),
        do: kv_list_embed(user_id),
        else: moved_embed()

    DiscordApi.send_message(channel_id, embed)
  end

  def handle_interaction(interaction) do
    user_id = InteractionHandler.user_id(interaction)

    DiscordApi.respond_to_interaction(
      interaction["id"],
      interaction["token"],
      kv_list_embed(user_id)
    )
  end

  defp kv_list_embed(user_id) do
    keys =
      Lanyard.KV.Interface.get_all(user_id)
      |> Enum.map(fn {k, _v} -> k end)

    keys_value =
      case keys do
        [] -> "_No keys yet._"
        list -> "```#{Enum.join(list, ", ")}```"
      end

    Embed.info(%{
      title: ":file_folder: Your K/V Store",
      description:
        "#{CommandCache.mention("get")} `<key>` — get a value\n#{CommandCache.mention("set")} `<key> <value>` — set a key\n#{CommandCache.mention("del")} `<key>` — delete a key",
      fields: [
        %{name: "Keys (#{length(keys)})", value: keys_value, inline: false}
      ]
    })
  end

  defp moved_embed do
    Embed.info(%{
      title: ":sparkles: K/V commands have moved",
      description:
        "Use #{CommandCache.mention("kv")} to view your keys, #{CommandCache.mention("get")} to retrieve, #{CommandCache.mention("set")} to update, or #{CommandCache.mention("del")} to remove."
    })
  end

  defp dm?(payload), do: is_nil(payload["guild_id"])
end
