use Mix.Config

config :lanyard,
  bot_token: System.get_env("BOT_TOKEN"),
  redis_host: "localhost"
