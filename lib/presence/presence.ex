defmodule Lanyard.Presence.PublicFields do
  defstruct [:user_id, :discord_user, :discord_presence, :kv]
end

defmodule Lanyard.Presence do
  use GenServer

  alias Lanyard.Presence.Spotify
  alias Lanyard.Presence.Activity

  defstruct user_id: nil,
            discord_user: nil,
            discord_presence: nil,
            kv: nil,
            subscriber_pids: nil,
            refmap: nil

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :"presence:#{state.user_id}")
  end

  def init(state) do
    kv = Lanyard.Connectivity.Redis.hgetall("lanyard_kv:#{state.user_id}")

    {:ok, pretty_presence} =
      state
      |> Map.put(:kv, kv)
      |> get_public_fields()
      |> build_pretty_presence()

    subscriber_pids = Lanyard.SocketHandler.get_global_subscriber_list()

    Manifold.send(
      subscriber_pids,
      {:remote_send, %{op: 0, t: "PRESENCE_UPDATE", d: pretty_presence}}
    )

    {:ok,
     %__MODULE__{
       user_id: state.user_id,
       discord_presence: state.discord_presence,
       discord_user: state.discord_user,
       kv: kv,
       subscriber_pids: subscriber_pids,
       refmap: %{}
     }}
  end

  def handle_call({:get_raw_data}, _from, state) do
    {:reply, get_public_fields(state), state}
  end

  def handle_info({:add_subscriber, pid}, state) do
    ref = Process.monitor(pid)

    {:noreply,
     %{
       state
       | subscriber_pids: [pid | state.subscriber_pids],
         refmap: Map.put(state.refmap, pid, ref)
     }}
  end

  def handle_info({:remove_subscriber, pid}, state) do
    ref = Map.get(state.refmap, pid)

    unless ref == nil do
      Process.demonitor(ref)
    end

    {:noreply, %{state | subscriber_pids: Map.delete(state.subscriber_pids, pid)}}
  end

  def handle_cast({:sync, new_state}, state) do
    {_, pretty_presence} =
      build_pretty_presence(
        get_public_fields(
          %{
            discord_user: state.discord_user,
            discord_presence: state.discord_presence,
            user_id: state.user_id,
            kv: state.kv
          }
          |> Map.merge(new_state)
        )
      )

    Manifold.send(
      state.subscriber_pids,
      {:remote_send, %{op: 0, t: "PRESENCE_UPDATE", d: pretty_presence}}
    )

    Task.start(fn ->
      Lanyard.Analytics.presence_tick(state.user_id, pretty_presence)
    end)

    {:noreply, Map.merge(state, new_state)}
  end

  def handle_info({:DOWN, _ref, :process, object, _reason}, state) do
    {:noreply,
     %{state | subscriber_pids: state.subscriber_pids |> Enum.reject(fn sub -> sub == object end)}}
  end

  @spec get_public_fields(any()) :: Lanyard.Presence.PublicFields
  defp get_public_fields(state) do
    %Lanyard.Presence.PublicFields{
      user_id: state.user_id,
      discord_user: state.discord_user,
      discord_presence: state.discord_presence,
      kv: state.kv
    }
  end

  #
  # Public API
  #

  @spec get_presence(binary) :: {:ok, any} | {:error, atom, binary}
  def get_presence(user_id) when is_number(user_id) do
    get_presence(Integer.to_string(user_id))
  end

  @spec get_presence(binary) :: {:ok, any} | {:error, atom, binary}
  def get_presence(user_id) when is_binary(user_id) do
    case GenRegistry.lookup(__MODULE__, user_id) do
      {:ok, pid} ->
        {:ok, GenServer.call(pid, {:get_raw_data})}

      {:error, _reason} ->
        {:error, :user_not_monitored, "User is not being monitored by Lanyard"}
    end
  end

  @doc """
  Returns the given user IDs pretty presence.
  Tries to hit cache first - if no result, builds from raw data
  """
  @spec get_pretty_presence(binary) :: {:ok, any} | {:error, atom, binary}
  def get_pretty_presence(user_id) do
    case :ets.lookup(:cached_presences, user_id) do
      [{_id, cached}] ->
        {:ok, cached}

      _ ->
        case get_presence(user_id) do
          {:ok, raw_presence} ->
            build_pretty_presence(raw_presence)

          err ->
            err
        end
    end
  end

  def build_pretty_presence(raw_data) do
    activities = raw_data.discord_presence[:activities] || []

    spotify_activity =
      activities
      |> Enum.find(fn activity ->
        activity.id == Application.get_env(:lanyard, :discord_spotify_activity_id)
      end)

    has_presence? = raw_data.discord_presence !== nil

    pretty_fields =
      if has_presence? do
        %{
          discord_user: Map.put(raw_data.discord_user, :id, "#{raw_data.discord_user.id}"),
          discord_status: raw_data.discord_presence.status,
          active_on_discord_web: Map.has_key?(raw_data.discord_presence.client_status, :web),
          active_on_discord_desktop:
            Map.has_key?(raw_data.discord_presence.client_status, :desktop),
          active_on_discord_mobile:
            Map.has_key?(raw_data.discord_presence.client_status, :mobile),
          listening_to_spotify: spotify_activity !== nil,
          spotify: Spotify.build_pretty_spotify(spotify_activity),
          activities: Activity.build_pretty_activities(raw_data.discord_presence.activities),
          kv: raw_data.kv
        }
      else
        %{
          discord_user: Map.put(raw_data.discord_user, :id, "#{raw_data.discord_user.id}"),
          discord_status: "offline",
          active_on_discord_web: false,
          active_on_discord_desktop: false,
          active_on_discord_mobile: false,
          listening_to_spotify: false,
          spotify: nil,
          activities: [],
          kv: raw_data.kv
        }
      end

    :ets.insert(:cached_presences, {"#{raw_data.discord_user.id}", pretty_fields})

    {:ok, pretty_fields}
  end

  def subscribe_to_ids_and_build(ids) do
    ids
    |> Enum.reduce(%{}, fn id, acc ->
      case GenRegistry.lookup(__MODULE__, id) do
        {:ok, pid} ->
          {:ok, presence} = get_pretty_presence(id)
          send(pid, {:add_subscriber, self()})
          %{"#{id}": presence} |> Map.merge(acc)

        _ ->
          acc
      end
    end)
  end

  def sync(user_id, payload) do
    with {:ok, pid} <-
           GenRegistry.lookup(__MODULE__, Integer.to_string(user_id)) do
      GenServer.cast(pid, {:sync, payload})
    end
  end
end
