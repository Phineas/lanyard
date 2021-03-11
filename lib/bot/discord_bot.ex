defmodule Lanyard.DiscordBot do
  use GenServer

  alias Lanyard.Gateway

  defstruct token: nil,
            gateway_client_pid: nil

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: :discord_bot)
  end

  def init(state) do
    {:ok, %__MODULE__{token: state.token, gateway_client_pid: nil}, {:continue, :setup_bot}}
  end

  def handle_continue(:setup_bot, state) do
    {_, pid} = Lanyard.Gateway.Client.start_link(%{token: state.token})

    {:noreply, state}
  end
end
