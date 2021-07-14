defmodule Lanyard.Presence.Activity do
  def build_pretty_activities(activities) do
    activities
    |> Enum.map(fn activity ->
      activity
      |> decorate_app_id
      |> decorate_emoji
    end)
  end

  defp decorate_app_id(%{application_id: application_id} = activity)
       when not is_binary(application_id),
       do: %{activity | application_id: "#{application_id}"}

  defp decorate_app_id(activity), do: activity

  defp decorate_emoji(%{emoji: %{id: emoji_id} = emoji} = activity) when is_number(emoji_id),
    do: %{activity | emoji: %{emoji | id: "#{emoji_id}"}}

  defp decorate_emoji(%{emoji: %{name: emoji_name} = emoji} = activity)
       when is_binary(emoji_name),
       do: %{activity | emoji: emoji}

  defp decorate_emoji(activity), do: activity
end
