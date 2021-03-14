defmodule Lanyard.Presence do
  use GenServer

  defstruct user_id: nil,
            discord_user: nil,
            discord_presence: nil,
            subscriber_pids: nil

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :"presence:#{state.user_id}")
  end

  def init(state) do
    IO.inspect state
    {:ok, %__MODULE__{user_id: state.user_id, discord_presence: state.discord_presence, discord_user: state.discord_user, subscriber_pids: []}}
  end

  def handle_call({:get_raw_data}, _from, state) do
    {:reply, get_public_fields(state), state}
  end

  def handle_cast({:add_subscriber, pid}, state) do
    Process.monitor(pid)
    {:noreply, %{state | subscriber_pids: [pid | state.subscriber_pids]}}
  end

  def handle_cast({:sync, new_state}, state) do
    {_, pretty_presence} = build_pretty_presence(get_public_fields(new_state |> Map.merge(%{discord_user: state.discord_user, user_id: state.user_id})))
    state.subscriber_pids |> Enum.each(fn sub -> send(sub, {:remote_send, %{op: 0, t: "PRESENCE_UPDATE", d: pretty_presence}}) end)
    {:noreply, Map.merge(state, new_state)}
  end

  # def handle_cast({:gateway_presence_update, presence}, state) do
  #   {:noreply, Map.merge(state, new_state)}
  # end

  def handle_info({:DOWN, ref, :process, object, reason}, state) do
    {:noreply, %{state | subscriber_pids: state.subscriber_pids |> Enum.reject(fn sub -> sub == object end)}}
  end

  @spec get_public_fields(__MODULE__) :: any
  defp get_public_fields(state) do
    %{
      user_id: state.user_id,
      discord_user: state.discord_user,
      discord_presence: state.discord_presence
    }
  end

  #
  # Public API
  #

  @spec get_presence(binary) :: {:ok, any} | {:error, atom, binary}
  def get_presence(user_id) when is_binary(user_id) do
    case GenRegistry.lookup(__MODULE__, user_id) do
      {:ok, pid} ->
         {:ok, GenServer.call(pid, {:get_raw_data})}
      {:error, _reason} ->
        {:error, :user_not_monitored, "User is not being monitored by Lanyard"}
    end
  end

  def build_pretty_presence(raw_data) do
    activities = raw_data.discord_presence[:activities] || []

    spotify_activity = activities
    |> Enum.find(fn activity ->
      activity.id == Application.get_env(:lanyard, :discord_spotify_activity_id)
    end)

    [_asset_host_id, spotify_album_art_id] = unless spotify_activity == nil do
      spotify_activity.assets.large_image
      |> String.split(":")
    else
      ["spotify", nil]
    end

    pretty_spotify = if spotify_activity !== nil, do: %{
      artist: spotify_activity.state,
      song: spotify_activity.details,
      album: spotify_activity.assets.large_text,
      album_art_url: "https://i.scdn.co/image/#{spotify_album_art_id}",
      timestamps: spotify_activity.timestamps
    }, else: nil

    activities = raw_data.discord_presence.activities
    |> Enum.map(fn activity ->
      application_id = if Map.has_key?(activity, :application_id) do
        "#{activity.application_id}"
      else
        nil
      end

      %{
        activity |
        application_id: application_id
      }
    end)

    has_presence? = raw_data.discord_presence !== nil

    pretty_fields = if has_presence? do
      %{
        discord_user: Map.put(raw_data.discord_user, :id, "#{raw_data.discord_user.id}"),
        discord_status: raw_data.discord_presence.status,
        active_on_discord_desktop: Map.has_key?(raw_data.discord_presence.client_status, :desktop),
        active_on_discord_mobile: Map.has_key?(raw_data.discord_presence.client_status, :mobile),
        listening_to_spotify: spotify_activity !== nil,
        spotify: pretty_spotify,
        activities: activities
      }
    else
      %{
        discord_user: Map.put(raw_data.discord_user, :id, "#{raw_data.discord_user.id}"),
        discord_status: "offline",
        active_on_discord_desktop: false,
        active_on_discord_mobile: false,
        listening_to_spotify: false,
        spotify: nil,
        activities: []
      }
    end

    {:ok, pretty_fields}
  end
end
