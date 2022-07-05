defmodule Lanyard.Presence.Spotify do
  def build_pretty_spotify(activity) when is_map(activity) do
    %{
      track_id: get_track_id(activity),
      artist: activity.state,
      song: activity.details,
      album: get_album_title(activity),
      album_art_url: get_album_art_url(activity),
      timestamps: activity.timestamps
    }
  end

  def build_pretty_spotify(activity) when is_nil(activity), do: nil

  defp get_track_id(%{sync_id: sync_id}) when is_binary(sync_id), do: sync_id
  defp get_track_id(_else), do: nil

  defp get_album_title(%{assets: large_text}), do: large_text
  defp get_album_title(_activity), do: nil

  defp get_album_art_url(%{assets: %{large_image: large_image}}) do
    case String.split(large_image, ":") do
      [_asset_resource_type, art_id] ->
        "https://i.scdn.co/image/#{art_id}"

      _ ->
        nil
    end
  end

  defp get_album_art_url(_activity), do: nil
end
