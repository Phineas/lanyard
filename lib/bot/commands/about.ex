defmodule Lanyard.DiscordBot.Commands.About do
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Embed

  def definition do
    %{
      name: "about",
      description: "View Lanyard's privacy policy and terms of service"
    }
  end

  def handle(_, payload) do
    DiscordApi.send_message(payload["channel_id"], embed())
  end

  def handle_interaction(interaction) do
    DiscordApi.respond_to_interaction(interaction["id"], interaction["token"], embed())
  end

  defp embed do
    base = Application.get_env(:lanyard, :external_url)

    Embed.info(%{
      title: "Lanyard",
      description:
        "Discord presence as an API. Embed your status on websites, dashboards, and more.\n\n:lock: **Privacy Policy:** #{base}/privacy\n:scroll: **Terms of Service:** #{base}/terms",
      footer: %{text: "lanyard.rest"}
    })
  end
end
