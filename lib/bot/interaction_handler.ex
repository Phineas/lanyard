defmodule Lanyard.DiscordBot.InteractionHandler do
  alias Lanyard.DiscordBot.DiscordApi
  alias Lanyard.DiscordBot.Embed

  @command_map %{
    "get" => Lanyard.DiscordBot.Commands.Get,
    "set" => Lanyard.DiscordBot.Commands.Set,
    "del" => Lanyard.DiscordBot.Commands.Del,
    "kv" => Lanyard.DiscordBot.Commands.KV,
    "about" => Lanyard.DiscordBot.Commands.About,
    "help" => Lanyard.DiscordBot.Commands.Help,
    "apikey" => Lanyard.DiscordBot.Commands.ApiKey
  }

  @application_command 2

  def handle_interaction(%{"type" => @application_command, "data" => %{"name" => name}} = interaction) do
    case @command_map[name] do
      nil ->
        :ok

      module ->
        if Lanyard.Presence.monitored?(user_id(interaction)) do
          module.handle_interaction(interaction)
        else
          DiscordApi.respond_to_interaction(
            interaction["id"],
            interaction["token"],
            Embed.not_monitored(),
            ephemeral: true
          )
        end
    end
  end

  def handle_interaction(_), do: :ok

  def user_id(interaction) do
    cond do
      user = interaction["user"] -> user["id"]
      member = interaction["member"] -> member["user"]["id"]
      true -> nil
    end
  end

  def option(interaction, name) do
    case get_in(interaction, ["data", "options"]) do
      nil ->
        nil

      options ->
        Enum.find_value(options, fn opt ->
          if opt["name"] == name, do: opt["value"]
        end)
    end
  end

  def command_definitions do
    @command_map
    |> Map.values()
    |> Enum.uniq()
    |> Enum.map(& &1.definition())
  end
end
