defmodule Ithkuil.MixProject do
  use Mix.Project

  def project do
    [
      app: :ithkuil,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: [],
      test_coverage: [summary: [threshold: 80]],
      description: "iffywow New Ithkuil coordinate codec (codec-v1) — production Elixir SDK",
      source_url: "https://github.com/noizu/iffywow"
    ]
  end

  def application do
    # Pure library: no supervision tree, no extra applications.
    [extra_applications: []]
  end
end
