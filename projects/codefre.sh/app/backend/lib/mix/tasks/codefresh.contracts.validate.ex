defmodule Mix.Tasks.Codefresh.Contracts.Validate do
  use Mix.Task

  @shortdoc "Validates frozen CodeFresh M0 contract artifacts"

  @contracts [
    {"OpenAPI", "../../docs/openapi.json", ["openapi", "paths"]},
    {"YAML script schema", "../../docs/arch/yaml-script.schema.json",
     ["$schema", "$id", "x-codefresh-contract-version", "properties"]},
    {"Rubric DSL schema", "../../docs/arch/rubric-dsl.schema.json",
     ["$schema", "$id", "x-codefresh-contract-version", "properties"]},
    {"OTLP receiver schema", "../../docs/arch/otlp-receiver.schema.json",
     ["$schema", "$id", "x-codefresh-contract-version", "$defs"]}
  ]

  @docs [
    {"YAML script docs", "../../docs/arch/yaml-script-schema.md"},
    {"Rubric DSL docs", "../../docs/arch/rubric-dsl.md"},
    {"OTLP receiver docs", "../../docs/arch/otlp-receiver-contract.md"}
  ]

  @impl Mix.Task
  def run(_args) do
    Enum.each(@contracts, &validate_json_contract!/1)
    Enum.each(@docs, &validate_frozen_doc!/1)
    Mix.shell().info("Validated #{length(@contracts) + length(@docs)} M0 contract artifacts")
  end

  defp validate_json_contract!({name, path, required_keys}) do
    artifact = read_artifact!(path)

    decoded =
      case Jason.decode(artifact) do
        {:ok, %{} = map} ->
          map

        {:ok, _} ->
          Mix.raise("#{name} must decode to a JSON object: #{path}")

        {:error, error} ->
          Mix.raise("#{name} is invalid JSON at #{path}: #{Exception.message(error)}")
      end

    missing = Enum.reject(required_keys, &Map.has_key?(decoded, &1))

    if missing != [] do
      Mix.raise("#{name} is missing required keys #{inspect(missing)} in #{path}")
    end
  end

  defp validate_frozen_doc!({name, path}) do
    content = read_artifact!(path)

    unless String.contains?(content, "Contract-frozen") or
             String.contains?(content, "contract-frozen") do
      Mix.raise("#{name} must state its contract-frozen status: #{path}")
    end
  end

  defp read_artifact!(path) do
    path = Path.expand(path, File.cwd!())

    case File.read(path) do
      {:ok, content} -> content
      {:error, reason} -> Mix.raise("Unable to read #{path}: #{:file.format_error(reason)}")
    end
  end
end
