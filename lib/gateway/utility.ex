defmodule Lanyard.Gateway.Utility do
  @opcodes %{
    dispatch: 0,
    heartbeat: 1,
    identify: 2,
    status_update: 3,
    voice_state_update: 4,
    voice_server_ping: 5,
    resume: 6,
    reconnect: 7,
    request_guild_members: 8,
    invalid_session: 9,
    hello: 10,
    heartbeat_ack: 11
  }

  @opcodes_by_value Map.new(@opcodes, fn {name, value} -> {value, name} end)

  @dispatch_events %{
    "READY" => :ready,
    "MESSAGE_CREATE" => :message_create,
    "GUILD_CREATE" => :guild_create,
    "PRESENCE_UPDATE" => :presence_update,
    "GUILD_MEMBER_ADD" => :guild_member_add,
    "GUILD_MEMBER_UPDATE" => :guild_member_update,
    "GUILD_MEMBER_REMOVE" => :guild_member_remove,
    "GUILD_MEMBERS_CHUNK" => :guild_members_chunk
  }

  @doc "Build a json  payload for discord communication"
  @spec payload_build_json(atom(), map(), number(), String.t()) :: binary()
  def payload_build_json(op, data, seq_num \\ nil, event_name \\ nil) do
    load = %{"op" => encode_opcode(op), "d" => data}

    load
    |> _update_payload(seq_num, "s", seq_num)
    |> _update_payload(event_name, "t", event_name)
    |> Jason.encode!()
  end

  @spec payload_decode({:text, binary()}) :: map()
  def payload_decode({:text, payload}) do
    payload = Jason.decode!(payload)
    op = decode_opcode(payload["op"])

    data = %{
      op: op,
      data: payload["d"],
      seq_num: payload["s"]
    }

    # only dispatch as `t`
    if op == :dispatch do
      Map.put(data, :event_name, decode_dispatch_event(payload["t"]))
    else
      data
    end
  end

  @doc "Generic function for getting the value from an agent process"
  @spec agent_value(pid) :: any
  def agent_value(agent) do
    Agent.get(agent, fn a -> a end)
  end

  @doc "Generic function for updating the value of an agent process"
  @spec agent_update(pid, any) :: nil
  def agent_update(agent, n) do
    if n != nil do
      Agent.update(agent, fn _a -> n end)
    end
  end

  defp encode_opcode(value), do: Map.fetch!(@opcodes, value)
  defp decode_opcode(value), do: Map.get(@opcodes_by_value, value, :unknown)
  defp decode_dispatch_event(value), do: Map.get(@dispatch_events, value, :unknown)

  # Makes it easy to just update and pipe a payload
  defp _update_payload(load, var, key, value) do
    if var do
      Map.put(load, key, value)
    else
      load
    end
  end
end
