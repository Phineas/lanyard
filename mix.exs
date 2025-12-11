defmodule Lanyard.MixProject do
  use Mix.Project

  def project do
    [
      app: :lanyard,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :corsica],
      mod: {Lanyard, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.19"},
      {:bandit, "~> 1.8"},
      {:websock_adapter, "~> 0.5.9"},
      {:prometheus_plugs, "~> 1.1"},
      {:prometheus_ex,
       git: "https://github.com/lanodan/prometheus.ex", branch: "fix/elixir-1.14", override: true},
      {:websocket_client, "~> 1.6"},
      {:jason, "~> 1.4"},
      {:gen_registry, "~> 1.3"},
      {:corsica, "~> 2.1"},
      {:manifold, "~> 1.6"},
      {:finch, "~> 0.20.0"},
      {:redix, "~> 1.5"}
    ]
  end
end
