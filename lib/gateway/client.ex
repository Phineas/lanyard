defmodule Lanyard.Gateway.Client do
  # a lot of functionality here is taken from: https://github.com/rmcafee/discord_ex/blob/master/lib/discord_ex/client/client.ex
  require Logger

  alias Lanyard.Gateway.Heartbeat

  import Lanyard.Gateway.Utility

  @behaviour :websocket_client

  def opcodes do
    %{
      :dispatch => 0,
      :heartbeat => 1,
      :identify => 2,
      :status_update => 3,
      :voice_state_update => 4,
      :voice_server_ping => 5,
      :resume => 6,
      :reconnect => 7,
      :request_guild_members => 8,
      :invalid_session => 9,
      :hello => 10,
      :heartbeat_ack => 11
    }
  end

  def start_link(state) do
    # state = state
    # |> Map.put(:guilds, [])
    # |> Map.put(:token, state.token)

    :crypto.start()
    :ssl.start()

    :websocket_client.start_link("wss://gateway.discord.gg/?v=9&encoding=etf", __MODULE__, [state])
  end

  def init([state]) do
    {:ok, agent_seq_num} = Agent.start_link(fn -> nil end)

    new_state =
      state
      # Pass the client state to use it
      |> Map.put(:client_pid, self())
      # Pass agent sequence num
      |> Map.put(:agent_seq_num, agent_seq_num)
      # Place for Heartbeat process pid
      |> Map.put(:heartbeat_pid, nil)

    {:once, new_state}
  end

  def onconnect(_WSReq, state) do
    # Send identifier to discord gateway
    identify(state)
    {:ok, state}
  end

  def ondisconnect({:remote, :closed}, state) do
    # Reconnection with resume opcode should be attempted here
    {:close, {:remote, :closed}, state}
  end

  def websocket_handle({:binary, payload}, _socket, state) do
    data = payload_decode(opcodes(), {:binary, payload})

    # Keeps the sequence tracker process updated
    _update_agent_sequence(data, state)

    # Handle data based on opcode sent by Discord
    _handle_data(data, state)
  end

  defp _handle_data(%{op: :hello} = data, state) do
    # Discord sends hello op immediately after connection
    # Start sending heartbeat with interval defined by the hello packet
    Logger.debug("Discord: Hello")

    {:ok, heartbeat_pid} =
      Heartbeat.start_link(
        state[:agent_seq_num],
        data.data.heartbeat_interval,
        self()
      )

    {:ok, %{state | heartbeat_pid: heartbeat_pid}}
  end

  defp _handle_data(%{op: :heartbeat_ack} = _data, state) do
    # Discord sends heartbeat_ack after we send a heartbeat
    # If ack is not received, the connection is stale
    Logger.debug("Discord: Heartbeat ACK")
    Heartbeat.ack(state[:heartbeat_pid])
    {:ok, state}
  end

  defp _handle_data(%{op: :dispatch, event_name: event_name} = data, state) do
    # Dispatch op carries actual content like channel messages
    if event_name == :READY do
      # Client is ready
      # Logger.debug(fn -> "Discord: Dispatch #{event_name}" end)
    end

    event = normalize_atom(event_name)

    handle_event({event, data}, state)
  end

  defp _handle_data(%{op: :reconnect} = _data, state) do
    Logger.warn("Discord enforced Reconnect")
    # Discord enforces reconnection. Websocket should be
    # reconnected and resume opcode sent to playback missed messages.
    # For now just kill the connection so that a supervisor can restart us.
    {:close, "Discord enforced reconnect", state}
  end

  defp _handle_data(%{op: :invalid_session} = _data, state) do
    Logger.warn("Discord: Invalid session")
    # On resume Discord will send invalid_session if our session id is too old
    # to be resumed.
    # For now just kill the connection so that a supervisor can restart us.
    {:close, "Invalid session", state}
  end

  def websocket_info(:start, _connection, state) do
    {:ok, state}
  end

  @doc "Look into state - grab key value and pass it back to calling process"
  def websocket_info({:get_state, key, pid}, _connection, state) do
    send(pid, {key, state[key]})
    {:ok, state}
  end

  @doc "Ability to update websocket client state"
  def websocket_info({:update_state, update_values}, _connection, state) do
    {:ok, Map.merge(state, update_values)}
  end

  @doc "Remove key from state"
  def websocket_info({:clear_from_state, keys}, _connection, state) do
    new_state = Map.drop(state, keys)
    {:ok, new_state}
  end

  def websocket_info({:update_status, new_status}, _connection, state) do
    payload = payload_build(opcode(opcodes(), :status_update), new_status)
    :websocket_client.cast(self(), {:binary, payload})
    {:ok, state}
  end

  def websocket_info(:heartbeat_stale, _connection, state) do
    # Heartbeat process reports stale connection. Websocket should be
    # reconnected and resume opcode sent to playback missed messages.
    # For now just kill the connection so that a supervisor can restart us.
    {:close, "Heartbeat stale", state}
  end

  @spec websocket_terminate(any(), any(), nil | keyword() | map()) :: :ok
  def websocket_terminate(reason, _conn_state, state) do
    Lanyard.Metrics.Collector.set(:gauge, :lanyard_monitored_users, 0)

    Logger.info("Websocket closed in state #{inspect(state)} with reason #{inspect(reason)}")
    Logger.info("Killing seq_num process!")
    Process.exit(state[:agent_seq_num], :kill)
    Logger.info("Killing rest_client process!")
    Process.exit(state[:rest_client], :kill)
    Logger.info("Killing heartbeat process!")
    Process.exit(state[:heartbeat_pid], :kill)
    :ok
  end

  def handle_event({:ready, payload}, state) do
    new_state = Map.put(state, :session_id, payload.data[:session_id])

    {:ok, new_state}
  end

  def handle_event({:message_create, payload}, state) do
    Task.start(fn ->
      Lanyard.DiscordBot.CommandHandler.handle_message(payload)
    end)

    {:ok, state}
  end

  def handle_event({:guild_create, payload}, state) do
    create_member_presences(payload)

    # The Lanyard guild is above the large_threshold, so we need to use Opcode 8: Request Guild Members
    request_payload =
      payload_build(opcode(opcodes(), :request_guild_members), %{
        "guild_id" => payload.data.id,
        "limit" => 0,
        "query" => "",
        "presences" => true
      })

    :websocket_client.cast(self(), {:binary, request_payload})

    {:ok, state}
  end

  def handle_event({:presence_update, payload}, state) do
    Lanyard.Metrics.Collector.inc(:counter, :lanyard_presence_updates)

    with {:ok, pid} <-
           GenRegistry.lookup(Lanyard.Presence, Integer.to_string(payload.data.user.id)) do
      GenServer.cast(pid, {:sync, %{discord_presence: payload.data}})
    end

    {:ok, state}
  end

  def handle_event({:guild_member_add, payload}, state) do
    Logger.debug("User #{payload.data["user"]["id"]} joined guild")

    Lanyard.Metrics.Collector.inc(:gauge, :lanyard_monitored_users)

    request_payload =
      payload_build(opcode(opcodes(), :request_guild_members), %{
        "guild_id" => payload.data["guild_id"],
        "user_ids" => [payload.data["user"]["id"]],
        "limit" => 1,
        "presences" => true
      })

    :websocket_client.cast(self(), {:binary, request_payload})

    {:ok, state}
  end

  def handle_event({:guild_member_update, payload}, state) do
    Logger.debug("User object for #{payload.data.user.id} was updated")

    with {:ok, pid} <-
           GenRegistry.lookup(Lanyard.Presence, Integer.to_string(payload.data.user.id)) do
      GenServer.cast(pid, {:sync, %{discord_user: payload.data.user}})
    end

    {:ok, state}
  end

  def handle_event({:guild_member_remove, payload}, state) do
    Logger.debug("User #{payload.data["user"]["id"]} left guild")

    Lanyard.Metrics.Collector.dec(:gauge, :lanyard_monitored_users)

    str_id = Integer.to_string(payload.data["user"]["id"])

    GenRegistry.stop(Lanyard.Presence, str_id)
    :ets.delete(:cached_presences, str_id)

    {:ok, state}
  end

  def handle_event({:guild_members_chunk, payload}, state) do
    Lanyard.Metrics.Collector.inc(:gauge, :lanyard_monitored_users, length(payload.data.members))

    create_member_presences(payload)

    {:ok, state}
  end

  def handle_event({_event, _payload}, state) do
    {:ok, state}
  end

  def identify(state) do
    data = %{
      "token" => state.token,
      "properties" => %{
        "$os" => "erlang-vm",
        "$browser" => "lanyard-worker",
        "$device" => "lanyard-genserver",
        "$referrer" => "",
        "$referring_domain" => ""
      },
      "presence" => %{
        "since" => nil,
        "game" => %{
          "name" => Application.get_env(:lanyard, :bot_presence),
          "type" => Application.get_env(:lanyard, :bot_presence_type)
        },
        "status" => "online"
      },
      "compress" => false,
      "large_threshold" => 250,
      "intents" => 4867
    }

    payload = payload_build(opcode(opcodes(), :identify), data)
    :websocket_client.cast(self(), {:binary, payload})
  end

  defp _update_agent_sequence(data, state) do
    if state[:agent_seq_num] && data.seq_num do
      agent_update(state[:agent_seq_num], data.seq_num)
    end
  end

  defp create_member_presences(payload) do
    Task.start(fn ->
      Enum.each(payload.data.members, fn member ->
        presence =
          payload.data.presences
          |> Enum.find(fn presence -> presence.user.id === member.user.id end)

        gen_init = %{
          user_id: Integer.to_string(member.user.id),
          discord_presence: presence,
          discord_user: member.user
        }

        {:ok, pid} = GenRegistry.lookup_or_start(Lanyard.Presence, gen_init.user_id, [gen_init])
        GenServer.cast(pid, {:sync, gen_init})
      end)
    end)
  end
end
