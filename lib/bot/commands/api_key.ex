defmodule Lanyard.DiscordBot.Commands.ApiKey do
  alias Lanyard.Connectivity.Redis
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Embed

  def definition do
    %{
      name: "apikey",
      description: "Generate (or regenerate) your private Lanyard API key"
    }
  end

  def handle(_, %{"channel_id" => channel_id, "guild_id" => _guild_id} = _p) do
    embed =
      Embed.error(%{
        title: ":x: DM only",
        description: "You can only perform this command in DMs with me."
      })

    DiscordApi.send_message(channel_id, embed)
  end

  def handle(_, payload) do
    user_id = payload["author"]["id"]
    key = generate_api_key(user_id)

    DiscordApi.send_message(payload["channel_id"], key_embed(user_id, key, ephemeral?: false))
  end

  def handle_interaction(interaction) do
    user_id = interaction_user_id(interaction)
    key = generate_api_key(user_id)

    DiscordApi.respond_to_interaction(
      interaction["id"],
      interaction["token"],
      key_embed(user_id, key, ephemeral?: true),
      ephemeral: true
    )
  end

  def contains_api_key?(user_id, candidates) do
    stored_key = Redis.get("user_api_key:#{user_id}")

    candidates
    |> List.wrap()
    |> Enum.any?(&(&1 == stored_key))
  end

  def leak_warning_embed do
    Embed.warn(%{
      title: ":warning: That looks like your API key",
      description:
        "Your private Lanyard API key isn't a K/V key or value — it's a separate credential for the HTTP API and shouldn't be pasted as a command argument.\n\nIf you think the key has been exposed and want to rotate it, run #{Lanyard.DiscordBot.CommandCache.mention("apikey")}."
    })
  end

  def generate_api_key(user_id) do
    key = "lnyd_#{:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)}"

    existing_key? = Redis.get("user_api_key:#{user_id}")

    if existing_key? do
      Redis.del("api_key:#{existing_key?}")
    end

    Redis.mset(["api_key:#{key}", user_id, "user_api_key:#{user_id}", key])

    key
  end

  defp key_embed(user_id, key, opts) do
    base = Application.get_env(:lanyard, :external_url)
    ephemeral? = Keyword.get(opts, :ephemeral?, false)

    save_line =
      if ephemeral? do
        "**Save this key now — this message is only visible to you and won't stick around.** You can always run #{Lanyard.DiscordBot.CommandCache.mention("apikey")} to generate a new one, but the old one will stop working."
      else
        "**Save this key somewhere safe.** You can always run #{Lanyard.DiscordBot.CommandCache.mention("apikey")} to generate a new one, but the old one will stop working."
      end

    Embed.info(%{
      title: "Lanyard API Key",
      description:
        "#{save_line}\n\n**Do not share or post this key anywhere — it lets anyone manage your Lanyard K/V.**\n\nThis key is not meant for front-end applications. For the public read endpoint, use your Discord user ID:\n#{base}/v1/users/#{user_id}",
      fields: [
        %{name: "Key", value: "||`#{key}`||\n-# *click to reveal*", inline: false}
      ],
      footer: %{text: "Run /apikey again if you need to regenerate"}
    })
  end

  defp interaction_user_id(interaction) do
    cond do
      user = interaction["user"] -> user["id"]
      member = interaction["member"] -> member["user"]["id"]
      true -> nil
    end
  end
end
