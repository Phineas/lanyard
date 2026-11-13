ExUnit.start()

{:ok, _} = Application.ensure_all_started(:prometheus_ex)
{:ok, _} = Application.ensure_all_started(:manifold)
Lanyard.Metrics.Collector.start()
