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
    DiscordApi.send_message(payload["channel_id"], kv_list_embed(payload["author"]["id"]))
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
        list -> keys_field(list, user_id)
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

  # Embed field values are capped at 1024 chars, users can have 512 keys of up to 255 chars each
  @max_field_length 1_024
  # Room for the code fence and the "...and N more" footer
  @reserved_length 120

  @doc false
  def keys_field(keys, user_id) do
    {shown, _length} =
      keys
      |> Enum.map(&String.replace(&1, "`", "`\u200b"))
      |> Enum.reduce_while({[], 0}, fn key, {acc, length} ->
        new_length = length + String.length(key) + 2

        if new_length > @max_field_length - @reserved_length,
          do: {:halt, {acc, length}},
          else: {:cont, {[key | acc], new_length}}
      end)

    content = "```#{shown |> Enum.reverse() |> Enum.join(", ")}```"

    case length(keys) - length(shown) do
      0 ->
        content

      hidden ->
        "#{content}…and #{hidden} more, see all at #{Application.get_env(:lanyard, :external_url)}/v1/users/#{user_id}"
    end
  end
end
