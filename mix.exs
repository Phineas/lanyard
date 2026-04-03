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
      {:prometheus, "~> 6.1", override: true},
      {:prometheus_ex, "~> 5.1", override: true},
      {:websocket_client, "~> 1.6"},
      {:jason, "~> 1.4"},
      {:gen_registry, git: "https://github.com/MeguminSama/gen_registry.git", branch: "fix/elixir-1.18"},
      {:corsica, "~> 2.1"},
      {:manifold, "~> 1.6"},
      {:finch, "~> 0.20.0"},
      {:redix, "~> 1.5"},
      {:mongodb_driver, "~> 1.4"},
      {:castore, "~> 1.0"}
    ]
  end
end
