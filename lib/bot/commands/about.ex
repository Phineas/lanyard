defmodule Lanyard.DiscordBot.Commands.About do
  alias Lanyard.DiscordBot.CommandCache
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Embed
  alias Lanyard.DiscordBot.InteractionHandler

  def definition do
    %{
      name: "about",
      description: "Learn what Lanyard is, how to use it, and where to find the docs"
    }
  end

  def handle(_, payload) do
    DiscordApi.send_message(payload["channel_id"], embed(payload["author"]["id"]))
  end

  def handle_interaction(interaction) do
    user_id = InteractionHandler.user_id(interaction)

    DiscordApi.respond_to_interaction(interaction["id"], interaction["token"], embed(user_id))
  end

  def embed(user_id) do
    base = Application.get_env(:lanyard, :external_url)

    Embed.info(%{
      title: ":wave: Hi, I'm Lanyard",
      description:
        "I expose your Discord presence as a public API. Embed your status on websites, dashboards, and more.\n\n**Slash commands:**\n#{CommandCache.mention("kv")} — view your K/V keys\n#{CommandCache.mention("get")} — get a value\n#{CommandCache.mention("set")} — set a key\n#{CommandCache.mention("del")} — delete a key\n#{CommandCache.mention("apikey")} — generate or rotate your private API key (response is private to you)\n#{CommandCache.mention("help")} — list all commands",
      fields: [
        %{name: "Your presence", value: "#{base}/v1/users/#{user_id}", inline: false},
        %{
          name: "Links",
          value:
            "[API/Socket docs](https://github.com/Phineas/lanyard#readme) · [Source code](https://github.com/Phineas/lanyard) · [Privacy policy](https://privacy.lanyard.rest/)",
          inline: false
        }
      ],
      footer: %{text: "lanyard.rest"}
    })
  end
end
