import Config

config :lanyard,
  discord_spotify_activity_id: "spotify:1"

import_config "#{Mix.env()}.exs"
