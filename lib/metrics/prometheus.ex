defmodule Lanyard.Metrics do
  use GenServer
  require Logger

  @flush_interval 60_000 # 1 minute

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  alias Lanyard.Connectivity.Persistence

  def init(_) do
    # Load initial values from Persistence (MongoDB first, then Redis)
    initial_values = Persistence.get_global_metrics()
    Lanyard.Metrics.Collector.start(initial_values)
    
    schedule_flush()
    
    {:ok, %{}}
  end

  def handle_info(:flush, state) do
    # Read current state and persist to whichever DB is available
    metrics = Lanyard.Metrics.Collector.get_all_metrics()
    Persistence.store_metrics(metrics)
    
    schedule_flush()
    {:noreply, state}
  end

  defp schedule_flush do
    Process.send_after(self(), :flush, @flush_interval)
  end
end
