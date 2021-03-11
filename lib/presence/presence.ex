defmodule Lanyard.Presence do
  use GenServer

  defstruct user_id: nil,
            discord_user: nil,
            discord_presence: nil

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :"presence:#{state.user_id}")
  end

  def init(state) do
    {:ok, %__MODULE__{user_id: state.user_id, discord_presence: state.discord_presence, discord_user: state.discord_user}}
  end

  def handle_call({:get_raw_data}, _from, state) do
    {:reply, get_public_fields(state), state}
  end

  def handle_cast({:sync, new_state}, state) do
    {:noreply, Map.merge(state, new_state)}
  end

  # def handle_cast({:gateway_presence_update, presence}, state) do
  #   {:noreply, Map.merge(state, new_state)}
  # end

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

    pretty_fields = %{
      # active_on_discord_desktop: raw_data.discord_presence.client_status.desktop !== nil,
      listening_to_spotify: spotify_activity !== nil,
      spotify: pretty_spotify
    }

    {:ok, Map.merge(raw_data, pretty_fields)}
  end
end
