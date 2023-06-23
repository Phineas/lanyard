defmodule Lanyard.MixProject do
  use Mix.Project

  def project do
    [
      app: :lanyard,
      version: "0.1.0",
      elixir: "~> 1.14",
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
      {:plug, "~> 1.14"},
      {:bandit, "~> 0.7.7"},
      {:websock_adapter, "~> 0.5.3"},
      {:prometheus_plugs, "~> 1.1"},
      {:prometheus_ex,
       git: "https://github.com/lanodan/prometheus.ex", branch: "fix/elixir-1.14", override: true},
      {:websocket_client, "~> 1.5"},
      {:jason, "~> 1.4"},
      {:gen_registry, "~> 1.0"},
      {:corsica, "~> 1.0"},
      {:manifold, "~> 1.0"},
      {:httpoison, "~> 1.8"},
      {:redix, "~> 1.2"}
    ]
  end
end
