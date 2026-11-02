defmodule Lanyard.DiscordBot.Commands.Help do
  alias Lanyard.DiscordBot.CommandCache
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Embed

  def definition do
    %{
      name: "help",
      description: "List Lanyard's commands"
    }
  end

  def handle(_, payload) do
    DiscordApi.send_message(payload["channel_id"], embed())
  end

  def handle_interaction(interaction) do
    DiscordApi.respond_to_interaction(interaction["id"], interaction["token"], embed(), ephemeral: true)
  end

  defp embed do
    Embed.info(%{
      title: "Lanyard Bot Commands",
      description:
        "Store and manage custom data on your Lanyard profile.\n\n#{CommandCache.mention("get")} `<key>` — get the value of a key\n#{CommandCache.mention("set")} `<key> <value>` — set a key to a value\n#{CommandCache.mention("del")} `<key>` — delete a key\n#{CommandCache.mention("kv")} — list all of your current keys\n#{CommandCache.mention("apikey")} — get (or regenerate) your API key, only visible to you\n#{CommandCache.mention("about")} — privacy policy",
      fields: [
        %{
          name: "Docs & Source",
          value:
            "[API/Socket docs](https://github.com/Phineas/lanyard#readme) · [Source code](https://github.com/Phineas/lanyard)",
          inline: false
        }
      ]
    })
  end
end
