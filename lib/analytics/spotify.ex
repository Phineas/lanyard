defmodule Lanyard.Analytics.Spotify do
  alias Lanyard.Connectivity.Redis

  def increment_plays(
        user_id,
        %{track_id: track_id, timestamps: %{start: start_timestamp}}
      )
      when is_binary(user_id) and is_binary(track_id) do
    analytics_key = "lanyard_analytics:#{user_id}:spotify:track:#{track_id}"

    case :ets.lookup(:analytics, analytics_key) do
      [{_, %{last_played: ^start_timestamp}}] ->
        # Stale presence update
        :nochange

      _ ->
        :ets.insert(:analytics, {analytics_key, %{last_played: start_timestamp}})
        Redis.hincrby("lanyard_analytics:#{user_id}:spotify:track:#{track_id}", "plays", 1)

        Redis.hset(
          "lanyard_analytics:#{user_id}:spotify:track:#{track_id}",
          "last_played",
          start_timestamp
        )

        :updated
    end
  end

  def increment_plays(_user_id, _track) do
    :nochange
  end
end
