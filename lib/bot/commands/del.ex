defmodule Lanyard.DiscordBot.Commands.Del do
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Embed
  alias Lanyard.DiscordBot.Commands.ApiKey
  alias Lanyard.DiscordBot.InteractionHandler

  def definition do
    %{
      name: "del",
      description: "Delete a key from your Lanyard K/V store",
      options: [
        %{name: "key", description: "The key to delete", type: 3, required: true}
      ]
    }
  end

  def handle(args, payload) do
    user_id = payload["author"]["id"]
    channel_id = payload["channel_id"]

    if ApiKey.contains_api_key?(user_id, args) do
      DiscordApi.send_message(channel_id, ApiKey.leak_warning_embed())
    else
      embed =
        case args do
          [key] -> kv_del_embed(user_id, key)
          _ -> usage_embed()
        end

      DiscordApi.send_message(channel_id, embed)
    end

    :ok
  end

  def handle_interaction(interaction) do
    user_id = InteractionHandler.user_id(interaction)
    key = InteractionHandler.option(interaction, "key")
    interaction_id = interaction["id"]
    interaction_token = interaction["token"]

    if ApiKey.contains_api_key?(user_id, key) do
      DiscordApi.respond_to_interaction(
        interaction_id,
        interaction_token,
        ApiKey.leak_warning_embed(),
        ephemeral: true
      )
    else
      DiscordApi.respond_to_interaction(
        interaction_id,
        interaction_token,
        kv_del_embed(user_id, key)
      )
    end
  end

  defp kv_del_embed(user_id, key) do
    Lanyard.KV.Interface.del(user_id, key)

    Embed.success(%{
      title: ":white_check_mark: Key Deleted",
      description: "Deleted key `#{key}` from your K/V store."
    })
  end

  defp usage_embed do
    Embed.error(%{
      title: ":x: Invalid usage",
      description: "Usage: `#{Application.get_env(:lanyard, :command_prefix)}del <key>`"
    })
  end
end
