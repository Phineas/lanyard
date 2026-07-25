defmodule Lanyard.DiscordBot.Commands.Help do
  alias Lanyard.DiscordBot.DiscordApi

  def handle(_, payload) do
    prefix = Application.get_env(:lanyard, :command_prefix)

    DiscordApi.send_message(payload["channel_id"], %{
      title: "Lanyard Bot Commands",
      description: "Store and manage custom data on your Lanyard profile.",
      color: 0x5865F2,
      fields: [
        %{name: "`#{prefix}get <key>`", value: "Get the value of a key", inline: false},
        %{name: "`#{prefix}set <key> <value>`", value: "Set a key to a value", inline: false},
        %{name: "`#{prefix}del <key>`", value: "Delete a key", inline: false},
        %{name: "`#{prefix}kv`", value: "List all of your current keys", inline: false},
        %{name: "`#{prefix}apikey`", value: "Get (or regenerate) your Lanyard API key, sent via DM", inline: false},
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
