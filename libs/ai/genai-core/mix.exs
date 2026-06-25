defmodule GenAICore.MixProject do
  use Mix.Project

  def project do
    [
      app: :genai_core,
      name: "GenAI Core",
      description: description(),
      package: package(),
      version: "0.3.2",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [
        main: "GenAI",
        extras: [
          "README.md",
          "CHANGELOG.md",
          "TODO.md",
          "CONTRIBUTING.md",
          "LICENSE"
        ]
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/project.plt"}
      ],
      test_coverage: [
        summary: [
          threshold: 40
        ],
        ignore_modules: []
      ]
    ]
  end

  defp description() do
    "Generative AI Wrapper: Core Protocols and Logic"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{
        project: "https://github.com/noizu-labs-ml/genai_core",
        noizu_labs: "https://github.com/noizu-labs",
        noizu_labs_machine_learning: "https://github.com/noizu-labs-ml",
        developer_github: "https://github.com/noizu"
      },
      files: [
        "lib",
        "BOOK.md",
        "CONTRIBUTING.md",
        "LICENSE",
        "mix.exs",
        "README.md",
        "TODO.md"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    dev_apps =
      if Mix.env() in [:dev] do
        [:ex_doc]
      else
        []
      end

    test_apps =
      if Mix.env() in [:test] do
        [:junit_formatter]
      else
        []
      end

    [
      extra_applications: [:logger, :jason] ++ dev_apps ++ test_apps
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    test_deps = [
      {:junit_formatter, "~> 3.3", only: [:test]},
      {:mimic, "~> 2.3", only: :test, optional: true}
    ]

    hex_repo_deps = [
      # Documentation Provider
      {:ex_doc, "~> 0.40", only: [:dev, :test], optional: true, runtime: false},

      # Static Analysis: Type Checking
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false, optional: true}
      # {:credo, "~> 1.0", runtime: false},
    ]

    common = [
      # html parser and api client
      {:floki, ">= 0.30.0", optional: true},
      {:finch, "~> 0.15", optional: true},

      # UUID Library
      {:elixir_uuid, "~> 1.2", optional: true},
      {:shortuuid, "~> 4.0", optional: true},

      # Core Libraries
      {:noizu_labs_core, "~> 0.1"},

      # JSON/YAML
      {:jason, "~> 1.2", optional: true},
      {:ymlr, "~> 5.0", optional: true},
      {:yaml_elixir, "~> 2.9", optional: true},
      {:sweet_xml, "~> 0.7", optional: true}
    ]

    common ++ hex_repo_deps ++ test_deps
  end
end
