import Config

if config_env() == :prod do
  config :lanyard,
    bot_token: System.get_env("BOT_TOKEN"),
    redis_host: System.get_env("REDIS_HOST")
end
