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
      ":white_check_mark: Your new Lanyard API key is `#{key}`\n\n**ABSOLUTELY DO NOT SHARE OR POST THIS KEY ANYWHERE IT WILL ALLOW ANYONE TO MANAGE YOUR LANYARD K/V**\n*Run this command again if you need to re-generate your key*"
    )
  end

  def validate_api_key(user_id, key) when is_binary(key) do
    case Redis.get("user_api_key:#{user_id}") do
      ^key ->
        {true}

      _ ->
        {false}
    end
  end

  def validate_api_key(user_id, key) when is_list(key) do
    Enum.map(key, fn apikey ->
      case Redis.get("user_api_key:#{user_id}") do
        ^apikey ->
          {true}

        _ ->
          {false}
      end
    end)
  end

  def generate_and_send_new(user_id) do
    key = generate_api_key()
    existing_key? = Redis.get("user_api_key:#{user_id}")

    if existing_key? do
      Redis.del("api_key:#{existing_key?}")
    end

    Redis.set("api_key:#{key}", user_id)
    Redis.set("user_api_key:#{user_id}", key)

    dm_channel = DiscordApi.create_dm(user_id)

    DiscordApi.send_message(
      dm_channel,
      ":repeat: **We've regenerated your api key as you used it in a K/V command.**\nYour new Lanyard API key is `#{key}`\n\n**ABSOLUTELY DO NOT SHARE OR POST THIS KEY ANYWHERE IT WILL ALLOW ANYONE TO MANAGE YOUR LANYARD K/V**\n*Run `.apikey` in this DM if you need to re-generate your key*"
    )
  end

  def generate_api_key() do
    symbols = '0123456789abcdef'
    symbol_count = Enum.count(symbols)
    for _ <- 1..32, into: "", do: <<Enum.at(symbols, :crypto.rand_uniform(0, symbol_count))>>
  end
end
