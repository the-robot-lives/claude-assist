defmodule HoloGraph.Docs.Document do
  @moduledoc """
  Envelope validation and server-side sanitization for the canonical HoloGraph
  UML `GraphDocument` payload.

  The frontend type (`frontend/src/lib/holograph/types.ts`) is canonical: the
  `graph_documents.document` jsonb column stores that shape verbatim. This module
  validates the envelope (`id`/`slug`/`title` strings, `version` number,
  `nodes`/`edges` arrays) and ports the sanitization semantics of
  `normalizeGraphDocument()` (`frontend/src/lib/holograph/document-io.ts`)
  server-side: nodes with unknown `kind` are dropped, node ids are de-duplicated,
  and edges with an unknown `kind` or an endpoint that does not resolve to a
  surviving node are dropped. Node/edge internals beyond that are treated as
  opaque and round-trip untouched.
  """

  @node_kinds ~w(system package service class interface function database agent)
  @edge_kinds ~w(contains calls depends_on publishes stores patches)

  @default_view %{"projection" => "trd-3d-uml", "activeLayer" => 0}
  @default_model_kind "uml"

  @spec node_kinds() :: [String.t()]
  def node_kinds, do: @node_kinds

  @spec edge_kinds() :: [String.t()]
  def edge_kinds, do: @edge_kinds

  @doc """
  Validates the document envelope, returning the payload with string keys.

  Mirrors the frontend's `isGraphDocument()` guard.
  """
  @spec validate(term()) :: {:ok, map()} | {:error, {:invalid_document, [String.t()]}}
  def validate(input) when is_map(input) do
    document = stringify(input)

    errors =
      []
      |> require_string(document, "id")
      |> require_string(document, "slug")
      |> require_string(document, "title")
      |> require_number(document, "version")
      |> require_list(document, "nodes")
      |> require_list(document, "edges")
      |> Enum.reverse()

    case errors do
      [] -> {:ok, document}
      errors -> {:error, {:invalid_document, errors}}
    end
  end

  def validate(_input), do: {:error, {:invalid_document, ["document must be an object"]}}

  @doc """
  Validates and sanitizes in one step.
  """
  @spec validate_and_normalize(term(), keyword()) ::
          {:ok, map()} | {:error, {:invalid_document, [String.t()]}}
  def validate_and_normalize(input, opts \\ []) do
    with {:ok, document} <- validate(input) do
      {:ok, normalize(document, opts)}
    end
  end

  @doc """
  Sanitizes a (already string-keyed) document payload.

  Options:
    * `:now` — `DateTime` used for the `updatedAt` fallback.
  """
  @spec normalize(map(), keyword()) :: map()
  def normalize(document, opts \\ []) when is_map(document) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    {nodes, node_ids} = normalize_nodes(Map.get(document, "nodes", []))
    edges = normalize_edges(Map.get(document, "edges", []), node_ids)

    document
    |> Map.put("nodes", nodes)
    |> Map.put("edges", edges)
    |> Map.put("modelKind", present(Map.get(document, "modelKind")) || @default_model_kind)
    |> Map.put("view", map_or_default(Map.get(document, "view"), @default_view))
    |> Map.put("updatedAt", present(Map.get(document, "updatedAt")) || iso8601(now))
  end

  @doc """
  Stamps the persisted version/timestamp onto the payload so the jsonb envelope
  never drifts from `graph_documents.current_version`.
  """
  @spec stamp(map(), pos_integer(), DateTime.t()) :: map()
  def stamp(document, version, %DateTime{} = now) when is_map(document) do
    document
    |> Map.put("version", version)
    |> Map.put("updatedAt", iso8601(now))
  end

  @doc """
  Summary row used by list endpoints (mirrors the frontend mock's list shape).
  """
  @spec summary(map()) :: map()
  def summary(document) when is_map(document) do
    %{
      id: Map.get(document, "id"),
      slug: Map.get(document, "slug"),
      title: Map.get(document, "title"),
      version: Map.get(document, "version"),
      updatedAt: Map.get(document, "updatedAt"),
      summary: Map.get(document, "summary"),
      nodeCount: length(list_or_empty(Map.get(document, "nodes"))),
      edgeCount: length(list_or_empty(Map.get(document, "edges")))
    }
  end

  @doc """
  Port of the frontend `slugify()` helper.
  """
  @spec slugify(term()) :: String.t()
  def slugify(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.replace(~r/^-+|-+$/, "")
    |> String.slice(0, 72)
    |> case do
      "" -> "untitled"
      slug -> slug
    end
  end

  def slugify(_value), do: "untitled"

  @doc """
  Recursively converts atom keys (and atom values) to strings so payloads built
  in Elixir round-trip through jsonb identically to payloads decoded from JSON.
  """
  @spec stringify(term()) :: term()
  def stringify(%DateTime{} = value), do: DateTime.to_iso8601(value)
  def stringify(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  def stringify(%Date{} = value), do: Date.to_iso8601(value)

  def stringify(%{__struct__: _} = value), do: value

  def stringify(value) when is_map(value) do
    Map.new(value, fn {k, v} -> {stringify_key(k), stringify(v)} end)
  end

  def stringify(value) when is_list(value), do: Enum.map(value, &stringify/1)
  def stringify(value) when is_nil(value) or is_boolean(value), do: value
  def stringify(value) when is_atom(value), do: Atom.to_string(value)
  def stringify(value), do: value

  # -- normalization -------------------------------------------------------

  defp normalize_nodes(nodes) when is_list(nodes) do
    {normalized, used} =
      nodes
      |> Enum.filter(&valid_node?/1)
      |> Enum.reduce({[], MapSet.new()}, fn node, {acc, used} ->
        label = Map.get(node, "label")
        current = Map.get(node, "id")

        {id, used} =
          if is_binary(current) and current != "" and not MapSet.member?(used, current) do
            {current, MapSet.put(used, current)}
          else
            id_for("node", label, used)
          end

        node =
          node
          |> Map.put("id", id)
          |> Map.put("description", present(Map.get(node, "description")) || default_description(label))
          |> Map.put("metrics", map_or_default(Map.get(node, "metrics"), metrics_for(label)))

        {[node | acc], MapSet.put(used, id)}
      end)

    {Enum.reverse(normalized), used}
  end

  defp normalize_nodes(_nodes), do: {[], MapSet.new()}

  defp valid_node?(node) when is_map(node), do: Map.get(node, "kind") in @node_kinds
  defp valid_node?(_node), do: false

  defp normalize_edges(edges, node_ids) when is_list(edges) do
    edges
    |> Enum.filter(&keep_edge?(&1, node_ids))
    |> Enum.with_index()
    |> Enum.map(fn {edge, index} ->
      kind = Map.get(edge, "kind")

      edge
      |> Map.put("id", present(Map.get(edge, "id")) || "edge-#{index + 1}")
      |> Map.put("label", present(Map.get(edge, "label")) || kind)
    end)
  end

  defp normalize_edges(_edges, _node_ids), do: []

  defp keep_edge?(edge, node_ids) when is_map(edge) do
    Map.get(edge, "kind") in @edge_kinds and
      MapSet.member?(node_ids, Map.get(edge, "sourceId")) and
      MapSet.member?(node_ids, Map.get(edge, "targetId"))
  end

  defp keep_edge?(_edge, _node_ids), do: false

  # Port of the frontend `idFor()` helper: the candidate is registered as used
  # by the generator itself.
  defp id_for(prefix, label, used) do
    base = "#{prefix}-#{slugify(label)}"
    do_id_for(base, base, 2, used)
  end

  defp do_id_for(base, candidate, index, used) do
    if MapSet.member?(used, candidate) do
      do_id_for(base, "#{base}-#{index}", index + 1, used)
    else
      {candidate, MapSet.put(used, candidate)}
    end
  end

  defp default_description(label) when is_binary(label), do: "#{label} UML element."
  defp default_description(_label), do: "UML element."

  # Port of the frontend `metricsFor()` helper.
  defp metrics_for(label) do
    seed =
      label
      |> to_string()
      |> String.to_charlist()
      |> Enum.sum()

    %{
      "complexity" => 18 + rem(seed, 43),
      "churn" => 8 + rem(seed, 29),
      "risk" => 10 + rem(seed, 38)
    }
  end

  # -- envelope checks -----------------------------------------------------

  defp require_string(errors, document, key) do
    case Map.get(document, key) do
      value when is_binary(value) -> errors
      _ -> ["#{key} must be a string" | errors]
    end
  end

  defp require_number(errors, document, key) do
    case Map.get(document, key) do
      value when is_number(value) -> errors
      _ -> ["#{key} must be a number" | errors]
    end
  end

  defp require_list(errors, document, key) do
    case Map.get(document, key) do
      value when is_list(value) -> errors
      _ -> ["#{key} must be an array" | errors]
    end
  end

  # -- misc ----------------------------------------------------------------

  defp stringify_key(key) when is_atom(key), do: Atom.to_string(key)
  defp stringify_key(key) when is_binary(key), do: key
  defp stringify_key(key), do: to_string(key)

  defp present(value) when is_binary(value) and value != "", do: value
  defp present(_value), do: nil

  defp map_or_default(value, _default) when is_map(value) and map_size(value) > 0, do: value
  defp map_or_default(_value, default), do: default

  defp list_or_empty(value) when is_list(value), do: value
  defp list_or_empty(_value), do: []

  defp iso8601(%DateTime{} = now), do: now |> DateTime.truncate(:millisecond) |> DateTime.to_iso8601()
end
