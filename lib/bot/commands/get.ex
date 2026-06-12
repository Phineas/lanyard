defmodule Lanyard.DiscordBot.Commands.Get do
  alias Lanyard.DiscordBot.CommandCache
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Embed
  alias Lanyard.DiscordBot.Commands.ApiKey
  alias Lanyard.DiscordBot.InteractionHandler

  def definition do
    %{
      name: "get",
      description: "Get a value from your Lanyard K/V store",
      options: [
        %{name: "key", description: "The key to get", type: 3, required: true}
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
            [key] ->
              case kv_get_embed(user_id, key) do
                {_kind, e} -> e
              end

            _ ->
              usage_embed()
          end

        DiscordApi.send_message(channel_id, embed)

      true ->
        DiscordApi.send_message(channel_id, moved_embed("get"))
    end

    :ok
  end

  def handle_interaction(interaction) do
    user_id = InteractionHandler.user_id(interaction)
    key = InteractionHandler.option(interaction, "key")
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
        case kv_get_embed(user_id, key) do
          {:ok, embed} ->
            DiscordApi.respond_to_interaction(interaction_id, interaction_token, embed)

          {:error, embed} ->
            DiscordApi.respond_to_interaction(interaction_id, interaction_token, embed,
              ephemeral: true
            )
        end
    end
  end

  defp kv_get_embed(user_id, key) do
    case Lanyard.KV.Interface.get(user_id, key) do
      {:ok, v} ->
        {:ok,
         Embed.success(%{
           title: ":white_check_mark: Key Retrieved",
           fields: [
             %{name: "Key", value: "`#{key}`", inline: false},
             %{
               name: "Value",
               value: "```#{String.replace(v, "`", "`​")}```",
               inline: false
             }
           ]
         })}

      {:error, msg} ->
        {:error, Embed.error(%{title: ":x: Error", description: msg})}
    end
  end

  defp usage_embed do
    Embed.error(%{
      title: ":x: Invalid usage",
      description: "Usage: `#{Application.get_env(:lanyard, :command_prefix)}get <key>`"
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
