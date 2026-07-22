defmodule HoloGraph.Docs.GraphDocument do
  @moduledoc """
  Runtime contract for HoloGraph documents.

  M0/M1 documents are loaded from fixtures. The struct mirrors the persistence
  skeleton without tying the app surface to a database implementation yet.
  """

  alias HoloGraph.Docs.PatchOperation

  @type lane :: %{
          required(:id) => String.t(),
          required(:title) => String.t(),
          optional(:status) => String.t(),
          optional(:parallelism) => non_neg_integer(),
          optional(:metadata) => map()
        }

  @type graph_node :: map()
  @type graph_edge :: map()

  @type t :: %__MODULE__{
          id: String.t(),
          slug: String.t(),
          title: String.t(),
          version: pos_integer(),
          summary: String.t() | nil,
          lanes: [lane()],
          nodes: [graph_node()],
          edges: [graph_edge()],
          patches: [PatchOperation.t()],
          metadata: map(),
          inserted_at: String.t() | nil,
          updated_at: String.t() | nil
        }

  @enforce_keys [:id, :slug, :title]
  defstruct [
    :id,
    :slug,
    :title,
    :summary,
    :inserted_at,
    :updated_at,
    version: 1,
    lanes: [],
    nodes: [],
    edges: [],
    patches: [],
    metadata: %{}
  ]

  @spec from_map(map()) :: {:ok, t()} | {:error, term()}
  def from_map(attrs) when is_map(attrs) do
    with {:ok, id} <- required_string(value(attrs, :id), :id),
         {:ok, slug} <- required_string(value(attrs, :slug), :slug),
         {:ok, title} <- required_string(value(attrs, :title), :title),
         {:ok, version} <- normalize_version(value_or_default(attrs, :version, 1)),
         {:ok, patches} <- normalize_patches(value_or_default(attrs, :patches, [])) do
      {:ok,
       %__MODULE__{
         id: id,
         slug: slug,
         title: title,
         version: version,
         summary: value(attrs, :summary),
         lanes: normalize_list(value(attrs, :lanes)),
         nodes: normalize_list(value(attrs, :nodes)),
         edges: normalize_list(value(attrs, :edges)),
         patches: patches,
         metadata: normalize_map(value(attrs, :metadata)),
         inserted_at: value(attrs, :inserted_at),
         updated_at: value(attrs, :updated_at)
       }}
    end
  end

  def from_map(_attrs), do: {:error, {:invalid_graph_document, :not_a_map}}

  @spec summary_map(t()) :: map()
  def summary_map(%__MODULE__{} = document) do
    %{
      id: document.id,
      slug: document.slug,
      title: document.title,
      version: document.version,
      summary: document.summary,
      lane_count: length(document.lanes),
      node_count: length(document.nodes),
      edge_count: length(document.edges),
      updated_at: document.updated_at,
      metadata: document.metadata
    }
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = document) do
    %{
      id: document.id,
      slug: document.slug,
      title: document.title,
      version: document.version,
      summary: document.summary,
      lanes: document.lanes,
      nodes: document.nodes,
      edges: document.edges,
      patches: Enum.map(document.patches, &PatchOperation.to_map/1),
      metadata: document.metadata,
      inserted_at: document.inserted_at,
      updated_at: document.updated_at
    }
  end

  defp normalize_patches(patches) when is_list(patches) do
    Enum.reduce_while(patches, {:ok, []}, fn patch, {:ok, acc} ->
      case PatchOperation.from_map(patch) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, patches} -> {:ok, Enum.reverse(patches)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_patches(_patches),
    do: {:error, {:invalid_graph_document, {:patches, :not_a_list}}}

  defp normalize_version(version) when is_integer(version) and version > 0, do: {:ok, version}

  defp normalize_version(version) when is_binary(version) do
    case Integer.parse(version) do
      {parsed, ""} when parsed > 0 -> {:ok, parsed}
      _ -> {:error, {:invalid_graph_document, {:version, version}}}
    end
  end

  defp normalize_version(version), do: {:error, {:invalid_graph_document, {:version, version}}}

  defp normalize_list(value) when is_list(value), do: value
  defp normalize_list(_value), do: []

  defp normalize_map(value) when is_map(value), do: value
  defp normalize_map(_value), do: %{}

  defp required_string(value, _field) when is_binary(value) and byte_size(value) > 0,
    do: {:ok, value}

  defp required_string(_value, field), do: {:error, {:invalid_graph_document, {field, :required}}}

  defp value(attrs, key) do
    cond do
      Map.has_key?(attrs, key) -> Map.get(attrs, key)
      Map.has_key?(attrs, Atom.to_string(key)) -> Map.get(attrs, Atom.to_string(key))
      true -> nil
    end
  end

  defp value_or_default(attrs, key, default) do
    case value(attrs, key) do
      nil -> default
      explicit -> explicit
    end
  end
end
