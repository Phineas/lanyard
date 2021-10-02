import Config

if config_env() == :prod do
  config :lanyard,
    bot_token: System.get_env("BOT_TOKEN")
end
