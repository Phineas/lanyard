defmodule Lanyard.Presence.Activity do
  def build_pretty_activities(activities) do
    activities
    |> Enum.map(fn activity ->
      activity
      |> decorate_app_id
      |> decorate_emoji
    end)
  end

  defp decorate_app_id(%{"application_id" => application_id} = activity)
       when is_integer(application_id),
       do: %{activity | "application_id" => "#{application_id}"}

  defp decorate_app_id(activity), do: activity

  defp decorate_emoji(%{"emoji" => %{"id" => emoji_id} = emoji} = activity)
       when is_integer(emoji_id),
       do: %{activity | "emoji" => %{emoji | "id" => "#{emoji_id}"}}

  defp decorate_emoji(activity), do: activity
end
