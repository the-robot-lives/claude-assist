defmodule HoloGraph.Docs.Fixtures do
  @moduledoc """
  Disk-fixture loading for HoloGraph documents.

  This used to be the runtime contract for `HoloGraph.Docs`; it is now a
  seed/import path only — `HoloGraph.Docs` is Repo-backed. The legacy
  lanes/kanban `HoloGraph.Docs.GraphDocument` struct survives here so the
  pre-existing `/api/v1/holograph/docs*` fixture endpoints keep working, while
  `payload/1` exposes the raw JSON for importing a fixture into the database.
  """

  alias HoloGraph.Docs.GraphDocument

  @spec list_documents() :: [GraphDocument.t()]
  def list_documents do
    dir()
    |> fixture_paths()
    |> Enum.reduce([], fn path, acc ->
      case load_path(path) do
        {:ok, document} -> [document | acc]
        {:error, _reason} -> acc
      end
    end)
    |> Enum.sort_by(& &1.slug)
  end

  @spec list_summaries() :: [map()]
  def list_summaries do
    Enum.map(list_documents(), &GraphDocument.summary_map/1)
  end

  @spec get_document(String.t()) :: {:ok, GraphDocument.t()} | {:error, :not_found}
  def get_document(id_or_slug) when is_binary(id_or_slug) do
    case Enum.find(list_documents(), &(&1.id == id_or_slug || &1.slug == id_or_slug)) do
      nil -> {:error, :not_found}
      document -> {:ok, document}
    end
  end

  def get_document(_id_or_slug), do: {:error, :not_found}

  @doc """
  Legacy echo import: parses a fixture into the lanes/kanban struct and applies
  caller-supplied id/slug/title/metadata overrides. Persists nothing.
  """
  @spec legacy_import(String.t(), map()) ::
          {:ok, GraphDocument.t()} | {:error, :not_found | :invalid_fixture | term()}
  def legacy_import(fixture, attrs \\ %{})

  def legacy_import(fixture, attrs) when is_binary(fixture) and is_map(attrs) do
    with {:ok, path} <- fixture_path(fixture),
         {:ok, document} <- load_path(path) do
      {:ok, apply_import_attrs(document, attrs)}
    end
  end

  def legacy_import(_fixture, _attrs), do: {:error, :invalid_fixture}

  @doc """
  Raw decoded JSON payload for a fixture, used by the database import path.
  """
  @spec payload(String.t()) :: {:ok, map()} | {:error, :not_found | :invalid_fixture | term()}
  def payload(fixture) when is_binary(fixture) do
    with {:ok, path} <- fixture_path(fixture),
         {:ok, body} <- File.read(path),
         {:ok, attrs} <- Jason.decode(body) do
      {:ok, attrs}
    else
      {:error, %Jason.DecodeError{} = error} -> {:error, {:invalid_json, Exception.message(error)}}
      {:error, reason} -> {:error, reason}
    end
  end

  def payload(_fixture), do: {:error, :invalid_fixture}

  @spec dir() :: String.t()
  def dir do
    case :code.priv_dir(:holo_graph) do
      path when is_list(path) -> Path.join(List.to_string(path), "fixtures/docs")
      {:error, _reason} -> Path.expand("../../../priv/fixtures/docs", __DIR__)
    end
  end

  defp fixture_paths(dir) do
    case File.ls(dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".json"))
        |> Enum.map(&Path.join(dir, &1))

      {:error, _reason} ->
        []
    end
  end

  defp fixture_path(fixture) do
    if Regex.match?(~r/^[a-zA-Z0-9_-]+$/, fixture) do
      path = Path.join(dir(), fixture <> ".json")

      if File.regular?(path), do: {:ok, path}, else: {:error, :not_found}
    else
      {:error, :invalid_fixture}
    end
  end

  defp load_path(path) do
    with {:ok, body} <- File.read(path),
         {:ok, attrs} <- Jason.decode(body),
         {:ok, document} <- GraphDocument.from_map(attrs) do
      {:ok, document}
    else
      {:error, %Jason.DecodeError{} = error} ->
        {:error, {:invalid_json, Exception.message(error)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp apply_import_attrs(%GraphDocument{} = document, attrs) do
    metadata =
      document.metadata
      |> Map.merge(map_value(attrs, "metadata", %{}))
      |> Map.put("imported_from_fixture", document.slug)

    %GraphDocument{
      document
      | id: string_value(attrs, "id", document.id),
        slug: string_value(attrs, "slug", document.slug),
        title: string_value(attrs, "title", document.title),
        metadata: metadata
    }
  end

  defp string_value(attrs, key, default) do
    case Map.get(attrs, key) || Map.get(attrs, atom_key(key)) do
      value when is_binary(value) and byte_size(value) > 0 -> value
      _ -> default
    end
  end

  defp map_value(attrs, key, default) do
    case Map.get(attrs, key) || Map.get(attrs, atom_key(key)) do
      value when is_map(value) -> value
      _ -> default
    end
  end

  defp atom_key("id"), do: :id
  defp atom_key("slug"), do: :slug
  defp atom_key("title"), do: :title
  defp atom_key("metadata"), do: :metadata
end
