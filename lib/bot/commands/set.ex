defmodule Lanyard.DiscordBot.Commands.Set do
  alias Lanyard.DiscordBot.CommandCache
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Embed
  alias Lanyard.DiscordBot.Commands.ApiKey
  alias Lanyard.DiscordBot.InteractionHandler

  def definition do
    %{
      name: "set",
      description: "Set a key in your Lanyard K/V store",
      options: [
        %{name: "key", description: "The key to set", type: 3, required: true},
        %{name: "value", description: "The value to store", type: 3, required: true}
      ]
    }
  end

  def handle(args, payload) do
    user_id = payload["author"]["id"]
    channel_id = payload["channel_id"]

    cond do
      leaked_api_key?(user_id, args) ->
        DiscordApi.send_message(channel_id, ApiKey.leak_warning_embed())

      dm?(payload) ->
        embed =
          case args do
            [key | value_parts] when value_parts != [] ->
              case kv_set_embed(user_id, key, Enum.join(value_parts, " ")) do
                {_kind, e} -> e
              end

            _ ->
              usage_embed()
          end

        DiscordApi.send_message(channel_id, embed)

      true ->
        DiscordApi.send_message(channel_id, moved_embed("set"))
    end

    :ok
  end

  def handle_interaction(interaction) do
    user_id = InteractionHandler.user_id(interaction)
    key = InteractionHandler.option(interaction, "key")
    value = InteractionHandler.option(interaction, "value")
    interaction_id = interaction["id"]
    interaction_token = interaction["token"]

    case ApiKey.validate_api_key(user_id, key) do
      {true} ->
        DiscordApi.respond_to_interaction(
          interaction_id,
          interaction_token,
          ApiKey.leak_warning_embed(),
          ephemeral: true
        )

      {false} ->
        case kv_set_embed(user_id, key, value) do
          {:ok, embed} ->
            DiscordApi.respond_to_interaction(interaction_id, interaction_token, embed)

          {:error, embed} ->
            DiscordApi.respond_to_interaction(interaction_id, interaction_token, embed,
              ephemeral: true
            )
        end
    end

    :ok
  end

  defp kv_set_embed(user_id, key, value) do
    case Lanyard.KV.Interface.set(user_id, key, value) do
      {:error, reason} ->
        {:error, Embed.error(%{title: ":x: Could not set key", description: reason})}

      _ ->
        external_url = Application.get_env(:lanyard, :external_url)
        profile_url = "#{external_url}/v1/users/#{user_id}"

        {:ok,
         Embed.success(%{
           title: ":white_check_mark: Key Set",
           description:
             "View it with #{CommandCache.mention("get")} or open [your profile](#{profile_url}).",
           fields: [
             %{name: "Key", value: "`#{key}`", inline: true}
           ]
         })}
    end
  end

  defp usage_embed do
    Embed.error(%{
      title: ":x: Invalid usage",
      description:
        "Usage: `#{Application.get_env(:lanyard, :command_prefix)}set <key> <value>`"
    })
  end

  defp dm?(payload), do: is_nil(payload["guild_id"])

  defp leaked_api_key?(user_id, args) do
    case ApiKey.validate_api_key(user_id, args) do
      results when is_list(results) -> Enum.any?(results, &match?({true}, &1))
      {true} -> true
      _ -> false
    end
  end

  defp moved_embed(name) do
    Embed.info(%{
      title: ":sparkles: K/V commands have moved",
      description: "Use #{CommandCache.mention(name)} instead."
    })
  end
end
