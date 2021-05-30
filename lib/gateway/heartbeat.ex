defmodule Lanyard.Gateway.Heartbeat do
  use GenServer
  require Logger
  import Lanyard.Gateway.Client, only: [opcodes: 0]
  import Lanyard.Gateway.Utility

  def start_link(agent_seq_num, interval, socket_pid, opts \\ []) do
    GenServer.start_link(__MODULE__, {agent_seq_num, interval, socket_pid}, opts)
  end

  def reset(pid) do
    GenServer.call(pid, :reset)
  end

  def ack(pid) do
    GenServer.call(pid, :ack)
  end

  def init({agent_seq_num, interval, socket_pid}) do
    state = %{
      agent_seq_num: agent_seq_num,
      interval: interval,
      socket_pid: socket_pid,
      timer: nil,
      ack?: true
    }

    send(self(), :beat)
    {:ok, state}
  end

  def handle_info(:beat, %{interval: interval, socket_pid: socket_pid, ack?: true} = state) do
    value = agent_value(state[:agent_seq_num])
    payload = payload_build(opcode(opcodes(), :heartbeat), value)
    :websocket_client.cast(socket_pid, {:binary, payload})
    timer = Process.send_after(self(), :beat, interval)
    {:noreply, %{state | ack?: false, timer: timer}}
  end

  def handle_info(:beat, %{socket_pid: socket_pid, ack?: false} = state) do
    send(socket_pid, :heartbeat_stale)
    {:noreply, %{state | timer: nil}}
  end

  def handle_call(:ack, _from, state) do
    {:reply, :ok, %{state | ack?: true}}
  end

  def handle_call(:reset, _from, %{timer: nil} = state) do
    send(self(), :beat)
    {:reply, :ok, %{state | ack?: true}}
  end

  def handle_call(:reset, _from, %{timer: timer} = state) do
    Process.cancel_timer(timer)
    send(self(), :beat)
    {:reply, :ok, %{state | ack?: true, timer: nil}}
  end

  def handle_call(msg, _from, state) do
    Logger.debug(fn -> "Heartbeat called with invalid message #{inspect(msg)}" end)
    {:noreply, state}
  end
end
