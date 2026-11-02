defmodule Lanyard.DiscordBot.Commands.Get do
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

    if ApiKey.contains_api_key?(user_id, args) do
      DiscordApi.send_message(channel_id, ApiKey.leak_warning_embed())
    else
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
      case kv_get_embed(user_id, key) do
        {:ok, embed} ->
          DiscordApi.respond_to_interaction(interaction_id, interaction_token, embed)

        {:error, embed} ->
          DiscordApi.respond_to_interaction(interaction_id, interaction_token, embed, ephemeral: true)
      end
    end
  end

  @max_field_length 1_024

  defp kv_get_embed(user_id, key) do
    case Lanyard.KV.Interface.get(user_id, key) do
      {:ok, v} ->
        {:ok,
         Embed.success(%{
           title: ":white_check_mark: Key Retrieved",
           fields: [
             %{name: "Key", value: "`#{key}`", inline: false},
             %{name: "Value", value: value_field(key, v, user_id), inline: false}
           ]
         })}

      {:error, msg} ->
        {:error, Embed.error(%{title: ":x: Error", description: msg})}
    end
  end

  @doc false
  def value_field(key, value, user_id) do
    content = "```#{String.replace(value, "`", "`\u200b")}```"

    if String.length(content) <= @max_field_length do
      content
    else
      "The value for `#{key}` is too long to display in Discord.\nView it at #{Application.get_env(:lanyard, :external_url)}/v1/users/#{user_id}"
    end
  end

  defp usage_embed do
    Embed.error(%{
      title: ":x: Invalid usage",
      description: "Usage: `#{Application.get_env(:lanyard, :command_prefix)}get <key>`"
    })
  end
end
