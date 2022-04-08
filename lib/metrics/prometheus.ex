defmodule Lanyard.Metrics do
  use Task, restart: :transient

  def start_link(_opts) do
    Task.start_link(fn ->
      Lanyard.Metrics.Collector.start()
      exit(:normal)
    end)
  end
end
