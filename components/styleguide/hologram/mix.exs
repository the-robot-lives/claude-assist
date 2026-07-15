defmodule Styleguide.MixProject do
  use Mix.Project

  def project do
    [
      app: :styleguide,
      version: "0.2.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers() ++ [:hologram],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Styleguide.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.8.1"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.2"},
      {:hologram, "~> 0.10.0"},
      # hologram needs gproc 1.x (may conflict with other stacks that pin 0.9)
      {:gproc, "~> 1.0", override: true},
      {:yaml_elixir, "~> 2.9"},
      # Authentik / OIDC (same stack as hologram-start-app)
      {:openid_connect, "~> 1.0"}
    ]
  end
end
