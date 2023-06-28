defmodule Lanyard.Gateway.Utility do
  @spec normalize_atom(atom) :: atom()
  def normalize_atom(atom) do
    atom |> Atom.to_string() |> String.downcase() |> String.to_atom()
  end

  @doc "Build a binary payload for discord communication"
  @spec payload_build(number, map, number, String.t()) :: binary
  def payload_build(op, data, seq_num \\ nil, event_name \\ nil) do
    load = %{"op" => op, "d" => data}

    load
    |> _update_payload(seq_num, "s", seq_num)
    |> _update_payload(event_name, "t", seq_num)
    |> :erlang.term_to_binary()
  end

  @doc "Build a json  payload for discord communication"
  @spec payload_build_json(number, map, number, String.t()) :: binary
  def payload_build_json(op, data, seq_num \\ nil, event_name \\ nil) do
    load = %{"op" => op, "d" => data}

    load
    |> _update_payload(seq_num, "s", seq_num)
    |> _update_payload(event_name, "t", seq_num)
    |> Jason.encode!()
  end

  @doc "Decode binary payload received from discord into a map"
  @spec payload_decode(list(), {:binary, binary()}) :: map
  def payload_decode(codes, {:binary, payload}) do
    payload = :erlang.binary_to_term(payload)

    %{
      op: opcode(codes, payload[:op] || payload["op"]),
      data: payload[:d] || payload["d"],
      seq_num: payload[:s] || payload["s"],
      event_name: payload[:t] || payload["t"]
    }
  end

  @doc "Decode json payload received from discord into a map"
  @spec payload_decode(list(), {:text, binary()}) :: map
  def payload_decode(codes, {:text, payload}) do
    payload = Jason.decode!(payload)

    %{
      op: opcode(codes, payload[:op] || payload["op"]),
      data: payload[:d] || payload["d"],
      seq_num: payload[:s] || payload["s"],
      event_name: payload[:t] || payload["t"]
    }
  end

  @doc "Get the integer value for an opcode using it's name"
  @spec opcode(map, atom) :: integer
  def opcode(codes, value) when is_atom(value) do
    codes[value]
  end

  @doc "Get the atom value of and opcode using an integer value"
  @spec opcode(map, integer) :: atom
  def opcode(codes, value) when is_integer(value) do
    {k, _value} = Enum.find(codes, fn {_key, v} -> v == value end)
    k
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

  # Makes it easy to just update and pipe a payload
  defp _update_payload(load, var, key, value) do
    if var do
      Map.put(load, key, value)
    else
      load
    end
  end
end
