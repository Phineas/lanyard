defmodule Lanyard.Analytics do
  alias Lanyard.Analytics.Spotify

  def presence_tick(user_id, presence_object) do
    if presence_object.spotify !== nil do
      Spotify.increment_plays(user_id, presence_object.spotify)
    end

    {:ok}
  end
end
