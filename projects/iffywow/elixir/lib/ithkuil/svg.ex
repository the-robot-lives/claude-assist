defmodule Ithkuil.SVG do
  @moduledoc """
  Standalone SVG export with embedded coordinate metadata, and exact tuple
  recovery from any SDK-generated SVG. Mirrors `../../web/src/metadata.js`
  (`sceneToSVG` / `extractCoordinate`).

  Every SVG we generate carries its own coordinate:

    * `data-ithkuil-schema` / `data-ithkuil-integer` attributes
    * a `<metadata id="ithkuil-coordinate">` JSON block whose `&` and `<`
      are escaped as `\\u0026` / `\\u003c` (both only ever occur inside JSON
      strings), so the metadata body can never break strict XML parsing

  so `extract_coordinate(render(model)) == {:ok, model.coordinate}` holds with
  no vision, OCR, or geometric inference. Recognition of *unannotated* glyphs
  is a deferred, separate subsystem — deliberately not implemented here.
  """

  alias Ithkuil.JSON

  @kind_attrs %{
    "base" => ~s(stroke-width="3"),
    "modifier" => ~s(stroke-width="2.4"),
    "diacritic" => ~s(stroke-width="2"),
    "connector" => ~s(stroke-width="1" stroke-dasharray="4 3" opacity="0.65"),
    "socket-marker" => ~s(stroke-width="1.25")
  }

  @doc """
  Render a scene model (from `Ithkuil.Scene.compile/2` / `Ithkuil.to_scene/1`)
  to a standalone SVG document string. `mode` is `:compact` or `:exploded`.
  """
  @spec render(Ithkuil.Scene.model(), :compact | :exploded) :: String.t()
  def render(model, mode \\ :compact)

  def render(model, mode) when mode in [:compact, :exploded] do
    [x, y, w, h] = model.view_box

    body =
      model.nodes
      |> Enum.map(&node_group(&1, mode))
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n")

    meta = metadata_json(model, mode)

    integer_attr =
      if truthy(model.integer),
        do: ~s( data-ithkuil-integer="#{esc(model.integer)}"),
        else: ""

    title =
      if truthy(model.latinized),
        do: "  <title>#{esc(model.latinized)}</title>\n",
        else: ""

    ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="#{f(x)} #{f(y)} #{f(w)} #{f(h)}") <>
      ~s( data-ithkuil-schema="#{esc(model.schema)}"#{integer_attr}) <>
      ~s( fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">\n) <>
      title <>
      ~s(  <metadata id="ithkuil-coordinate">#{meta}</metadata>\n) <>
      body <> "\n</svg>\n"
  end

  def render(_model, mode) do
    raise ArgumentError, "unknown mode: #{inspect(mode)}"
  end

  @doc """
  Exact coordinate recovery from an SDK-generated SVG string. Returns
  `{:ok, wire}` (the coordinate wire form as Elixir data) or
  `{:error, :no_metadata}` when the metadata was stripped — at which point the
  file is an ordinary unannotated drawing and belongs to the deferred
  recognition subsystem.
  """
  @spec extract_coordinate(String.t()) :: {:ok, Ithkuil.Coord.wire()} | {:error, :no_metadata}
  def extract_coordinate(svg_text) when is_binary(svg_text) do
    case extract_metadata(svg_text) do
      {:ok, %{"coordinate" => coordinate}} when is_list(coordinate) -> {:ok, coordinate}
      _ -> {:error, :no_metadata}
    end
  end

  @doc """
  Full metadata block (`schema`, `latinized`, `integer`, `mode`, `coordinate`)
  as a map with string keys, or `{:error, :no_metadata}`.
  """
  @spec extract_metadata(String.t()) :: {:ok, map()} | {:error, :no_metadata}
  def extract_metadata(svg_text) when is_binary(svg_text) do
    with {:ok, raw} <- find_metadata(svg_text),
         {:ok, parsed} when is_map(parsed) <- JSON.parse(raw) do
      {:ok, parsed}
    else
      _ -> {:error, :no_metadata}
    end
  end

  # ------------------------------------------------------------------
  # Internals
  # ------------------------------------------------------------------

  defp node_group(node, mode) do
    p = Map.fetch!(node, mode)
    path = Map.get(node, :path)

    if p.visible and is_binary(path) and path != "" do
      [tx, ty] = p.translate
      t = "translate(#{f(tx)} #{f(ty)}) rotate(#{f(p.rotate)}) scale(#{f(p.scale)})"
      extra = Map.get(@kind_attrs, node.kind, "")

      ~s(  <g data-node-id="#{esc(node.id)}" data-kind="#{esc(node.kind)}" transform="#{t}" #{extra}) <>
        ~s(><path d="#{esc(path)}"/></g>)
    else
      ""
    end
  end

  # JSON.stringify({schema, latinized, integer, mode, coordinate}) with & and <
  # escaped as JSON \u escapes — identical to web/src/metadata.js.
  defp metadata_json(model, mode) do
    JSON.encode(
      {:object,
       [
         {"schema", model.schema},
         {"latinized", model.latinized},
         {"integer", model.integer},
         {"mode", Atom.to_string(mode)},
         {"coordinate", model.coordinate}
       ]}
    )
    |> String.replace("&", "\\u0026")
    |> String.replace("<", "\\u003c")
  end

  defp find_metadata(svg_text) do
    case Regex.run(~r/<metadata id="ithkuil-coordinate">(.*?)<\/metadata>/s, svg_text) do
      [_, inner] ->
        {:ok, inner}

      nil ->
        case Regex.run(~r/<metadata\b[^>]*>(.*?)<\/metadata>/s, svg_text) do
          [_, inner] -> {:ok, inner}
          nil -> {:error, :no_metadata}
        end
    end
  end

  # JS truthiness for the optional string facts: nil and "" are falsy.
  defp truthy(nil), do: false
  defp truthy(""), do: false
  defp truthy(_), do: true

  defp esc(s) do
    s
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp f(n), do: JSON.format_number(n)
end
