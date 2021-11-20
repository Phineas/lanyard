defmodule Lanyard.DiscordBot.Commands.KV do
  alias Lanyard.DiscordBot.DiscordApi

  def handle(_, payload) do
    kv =
      Lanyard.KV.Interface.get_all(payload["author"]["id"])
      |> Enum.map(fn {k, _v} -> k end)
      |> Enum.join(", ")

    kv = if String.length(kv) > 0, do: kv, else: "No keys"

    DiscordApi.send_message(
      payload["channel_id"],
      "*Use `.get <key>` to get a value*\n**Keys:** ```#{kv}```"
    )
  end
end
