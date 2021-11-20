defmodule Lanyard.DiscordBot.Commands.ApiKey do
  alias Lanyard.Connectivity.Redis
  alias Lanyard.DiscordBot.DiscordApi

  def handle(_, %{"channel_id" => channel_id, guild_id: _guild_id} = p) do
    DiscordApi.send_message(channel_id, ":x: You can only perform this command in DMs with me")
  end

  def handle(_, payload) do
    key = generate_api_key()

    existing_key? = Redis.get("user_api_key:#{payload["author"]["id"]}")

    if existing_key? do
      Redis.del("api_key:#{existing_key?}")
    end

    Redis.set("api_key:#{key}", payload["author"]["id"])
    Redis.set("user_api_key:#{payload["author"]["id"]}", key)

    DiscordApi.send_message(
      payload["channel_id"],
      ":white_check_mark: Your new Lanyard API key is `#{key}`\n*React with :wastebasket: to delete this message*"
    )
  end

  defp generate_api_key do
    symbols = '0123456789abcdef'
    symbol_count = Enum.count(symbols)
    for _ <- 1..32, into: "", do: <<Enum.at(symbols, :crypto.rand_uniform(0, symbol_count))>>
  end
end
