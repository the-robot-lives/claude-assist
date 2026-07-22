# Kino.VegaLite — Interactive Vega-Lite charts in Elixir Livebook

Kino.VegaLite is the Livebook bridge for the `vega_lite` Elixir library. You build a chart declaratively with the pure-Elixir `VegaLite` DSL (which emits a Vega-Lite JSON spec), then wrap it in a `Kino.VegaLite` widget so Livebook renders it as an interactive SVG/Canvas chart and lets you stream new data points into it at runtime. It runs only inside a Livebook (or any Kino-aware runtime); the underlying spec is portable Vega-Lite JSON.

**Current Version**: `kino_vega_lite ~> 0.1.11`, `vega_lite ~> 0.1.9` (current)  **License**: Apache-2.0  **Runtime**: Livebook / Kino; renders Vega-Lite v5 in the browser

## Official Resources & Documentation
- Kino.VegaLite docs: https://hexdocs.pm/kino_vega_lite
- `vega_lite` (the DSL) docs: https://hexdocs.pm/vega_lite
- Repo: https://github.com/livebook-dev/kino_vega_lite
- Vega-Lite spec (upstream): https://vega.github.io/vega-lite/docs/
- Vega-Lite examples gallery: https://vega.github.io/vega-lite/examples/
- Livebook: https://livebook.dev/

## Installation & Setup
### Mix / Livebook setup cell
```elixir
Mix.install([
  {:kino_vega_lite, "~> 0.1.11"},
  {:kino, "~> 0.12"}
])
```
`kino_vega_lite` pulls in `vega_lite` transitively, but list it explicitly if you call the `VegaLite` DSL directly:
```elixir
Mix.install([
  {:kino_vega_lite, "~> 0.1.11"},
  {:vega_lite, "~> 0.1.9"},
  {:kino, "~> 0.12"}
])
```

### Aliasing
Idiomatic Livebook aliases both modules so code reads cleanly:
```elixir
alias VegaLite, as: Vl
```

### Smart cell (no code)
Livebook ships a **"Chart"** smart cell backed by Kino.VegaLite. Bind a data variable (a list of maps, an Explorer `DataFrame`, or any Table.Reader source), pick mark + x/y/color from dropdowns, and it generates the `VegaLite` code for you. Use it to bootstrap, then "Convert to code cell" to customize.

## Core Syntax / API Reference

### Two layers: the `VegaLite` DSL vs. the `Kino.VegaLite` widget
- `VegaLite.*` builds an **immutable spec** (returns a `%VegaLite{}` you keep piping).
- `Kino.VegaLite.new/1` wraps a finished spec in a **live widget** you can push data into.

A plain `%VegaLite{}` returned as a cell result already renders — you only need `Kino.VegaLite.new/1` when you intend to stream/replace data after render.

### `VegaLite` DSL essentials
```elixir
Vl.new(width: 400, height: 300, title: "Sales")   # options: :width, :height, :title, :padding, :background
|> Vl.data_from_values(data)                        # data: list of maps / keyword lists
|> Vl.mark(:bar)                                     # mark type
|> Vl.encode_field(:x, "category", type: :nominal)   # channel encoding
|> Vl.encode_field(:y, "value", type: :quantitative)
```

**`data_from_values/2,3`** — inline data. Accepts a list of maps or a columnar map; `only:` limits columns:
```elixir
Vl.data_from_values(data, only: ["category", "value"])
```
**`data_from_url/2`** — remote/CSV/JSON data:
```elixir
Vl.data_from_url("https://vega.github.io/editor/data/seattle-weather.csv")
```

**`mark/2,3`** — the geometry. Types: `:bar`, `:line`, `:point`, `:circle`, `:square`, `:area`, `:tick`, `:rect` (heatmap), `:rule`, `:text`, `:arc` (pie), `:boxplot`, `:errorband`, `:errorbar`, `:geoshape`, `:trail`. Third arg = mark props:
```elixir
Vl.mark(:point, filled: true, size: 80, opacity: 0.7, tooltip: true)
```

**`encode_field/4`** — bind a data field to a visual channel. Channels: `:x`, `:y`, `:x2`, `:y2`, `:color`, `:opacity`, `:size`, `:shape`, `:theta`, `:radius`, `:text`, `:tooltip`, `:order`, `:detail`, `:column`, `:row`, `:facet`. Field `type:` must be one of `:quantitative`, `:nominal`, `:ordinal`, `:temporal`, `:geojson`:
```elixir
Vl.encode_field(:color, "region", type: :nominal,
  scale: [scheme: "category10"], legend: [title: "Region"])
Vl.encode_field(:x, "date", type: :temporal, time_unit: :yearmonth)
Vl.encode_field(:y, "price", type: :quantitative, aggregate: :mean, axis: [format: "$,.0f"])
```

**`encode/3`** — encode a constant/datum value (not a field):
```elixir
Vl.encode(:color, value: "steelblue")
```

**`transform/2`** — filter/aggregate/derive before plotting:
```elixir
Vl.transform(filter: "datum.value > 40")
Vl.transform(calculate: "datum.price * 1.1", as: "adjusted")
Vl.transform(aggregate: [[op: "sum", field: "value", as: "total"]], groupby: ["category"])
```

**`param/3`** — interactive selections / signals (Vega-Lite v5 params):
```elixir
Vl.param("brush", select: [type: :interval, encodings: [:x]])
```

### Composition
```elixir
Vl.layers([mark_spec_1, mark_spec_2])   # overlay
Vl.concat([spec_a, spec_b], :horizontal) # side-by-side (:horizontal | :vertical | :wrappable)
```
Faceting is done via the `:column`/`:row`/`:facet` channels rather than a separate call.

### `Kino.VegaLite` widget functions
```elixir
widget = Kino.VegaLite.new(vl_spec)          # create a streamable widget
Kino.VegaLite.push(widget, %{x: 1, y: 9})    # append one datum
Kino.VegaLite.push_many(widget, list_of_maps)# append a batch
Kino.VegaLite.clear(widget)                  # remove all data (keep spec)
# Drive updates on a timer from a source stream:
Kino.VegaLite.periodically(widget, 200, 0, fn i ->
  Kino.VegaLite.push(widget, %{x: i, y: :math.sin(i / 10)})
  {:cont, i + 1}
end)
```
`push/3` accepts a `dataset:` option when the spec has multiple named datasets. `push`/`push_many` marshal maps to the chart's inline dataset — the field keys must match your `encode_field` names.

## Chart Types (marks) you can produce
Bar, grouped/stacked bar, line, multi-series line, area/stacked area, scatter (`:point`/`:circle`), bubble (size channel), heatmap (`:rect`), histogram (`bin: true`), pie/donut (`:arc` + `:theta`), boxplot, error bars/bands, tick strip plots, text labels, rule/reference lines, geographic (`:geoshape` + GeoJSON), and layered/faceted/concatenated combinations of any of these.

## How-To (worked recipes)

### How to add colors / a theme to a Vega-Lite chart
Color by a field with a named scheme, or set a fixed color, or theme globally with `config/2`:
```elixir
Vl.new(width: 400, height: 300)
|> Vl.data_from_values(data)
|> Vl.mark(:bar)
|> Vl.encode_field(:x, "category", type: :nominal)
|> Vl.encode_field(:y, "value", type: :quantitative)
|> Vl.encode_field(:color, "category", type: :nominal,
     scale: [scheme: "tableau10"])          # categorical palette
|> Vl.config(
     background: "#0f172a",
     axis: [labelColor: "#cbd5e1", titleColor: "#e2e8f0", gridColor: "#334155"],
     view: [stroke: :transparent]
   )
```
Continuous data: use `scale: [scheme: "viridis"]` (sequential) or `"redblue"` (diverging). A fixed color uses `Vl.encode(:color, value: "#22c55e")` instead of a field.

### How to build a streaming/live chart
Create the widget once, then push. Nothing re-runs the whole cell:
```elixir
chart =
  Vl.new(width: 500, height: 300)
  |> Vl.mark(:line)
  |> Vl.encode_field(:x, "t", type: :quantitative)
  |> Vl.encode_field(:y, "v", type: :quantitative)
  |> Kino.VegaLite.new()

Kino.VegaLite.periodically(chart, 100, 0, fn t ->
  Kino.VegaLite.push(chart, %{t: t, v: :rand.uniform()})
  if t < 500, do: {:cont, t + 1}, else: :halt
end)

chart
```

### How to make an interactive scatter with brushing + tooltip
```elixir
Vl.new(width: 500, height: 400)
|> Vl.data_from_url("https://vega.github.io/editor/data/cars.json")
|> Vl.mark(:point, tooltip: true)
|> Vl.param("brush", select: :interval)
|> Vl.encode_field(:x, "Horsepower", type: :quantitative)
|> Vl.encode_field(:y, "Miles_per_Gallon", type: :quantitative)
|> Vl.encode(:color,
     condition: [param: "brush", field: "Origin", type: :nominal],
     value: "lightgray")
```

### How to facet one chart per category
```elixir
Vl.new()
|> Vl.data_from_values(data)
|> Vl.mark(:line)
|> Vl.encode_field(:x, "date", type: :temporal)
|> Vl.encode_field(:y, "value", type: :quantitative)
|> Vl.encode_field(:column, "region", type: :nominal)
```

### How to feed an Explorer DataFrame into a chart
```elixir
require Explorer.DataFrame, as: DF
df = DF.new(category: ["A", "B", "C"], value: [30, 55, 43])

Vl.new(width: 300)
|> Vl.data_from_values(DF.to_rows(df))   # or pass df directly via the Chart smart cell
|> Vl.mark(:bar)
|> Vl.encode_field(:x, "category", type: :nominal)
|> Vl.encode_field(:y, "value", type: :quantitative)
```

## Do's and Don'ts
### ✅ Do
- Always set an explicit `type:` on `encode_field` — Vega-Lite behaves very differently for `:nominal` vs `:quantitative` vs `:temporal`.
- Alias `VegaLite, as: Vl` for readable pipelines.
- Use `Kino.VegaLite.new/1` + `push/2` for live data; keep the spec static and only stream rows.
- Use `data_from_url/2` for large/remote data so the payload isn't serialized through Elixir.
- Match `push` map keys exactly to your encoded field names.

### ❌ Don't
- Don't rebuild and re-render the whole `%VegaLite{}` on every new data point — that defeats streaming and flickers. Push instead.
- Don't push into a bare `%VegaLite{}` spec — `push/2` only works on a `Kino.VegaLite` widget.
- Don't pass giant inline datasets (tens of thousands of rows) via `data_from_values` — serialize cost + browser render both suffer; sample or aggregate first.
- Don't forget `type: :temporal` for dates; without it, axes sort lexically and time units break.
- Don't expect `push` to change the spec (marks, scales) — it only appends data.

## Styling, Theming & Customization
- **Per-encoding**: `scale:` (domain/range/scheme), `axis:` (format, title, grid, ticks), `legend:` (title, orient, symbolType).
- **Global**: `Vl.config/2` sets `axis`, `legend`, `view`, `background`, `mark`, `title` defaults across the chart. This is the Elixir equivalent of a Vega-Lite theme.
- **Named color schemes**: categorical (`category10`, `tableau10`, `set2`), sequential (`viridis`, `blues`, `magma`), diverging (`redblue`, `spectral`).
- **Titles/labels**: `Vl.new(title: "…")` or `config(title: [...])` for fonts/anchor.
- Dark-mode charts: set `config(background:)` plus light axis/label colors as shown above; Vega-Lite has no built-in dark theme, so theme via `config`.

## Advanced Features
- **Layering/concat**: overlay a line + points, or place small multiples side by side.
- **Params & selections**: interval brushing, point selection, and binding to sliders drive interactivity fully client-side.
- **Transforms**: filter/aggregate/bin/window/fold entirely in the spec — no need to pre-shape data in Elixir.
- **Export**: any `%VegaLite{}` → `VegaLite.Export.to_json/1`, `to_html/1`, or (with `:jason` + a renderer) SVG/PNG via `VegaLite.Convert` (`vega_lite_convert` package). The JSON is portable to any Vega-Lite renderer.
- **Table.Reader**: any source implementing the protocol (Explorer, `Kino.DataTable` data) can back a chart.

## Common Pitfalls & Troubleshooting
- **Blank chart**: usually a field-name mismatch between `encode_field` and your data keys, or missing `type:`.
- **Dates render as strings/misordered**: you omitted `type: :temporal`.
- **`push` does nothing**: you created the widget but returned the original spec, not the `Kino.VegaLite` widget, as the cell result — or keys don't match.
- **Slow notebook**: inline dataset too large; aggregate/sample, or use `data_from_url`.
- **Legend/scheme ignored**: `scale`/`legend` opts belong on the specific `encode_field` channel, not on `mark`.
- **Version skew**: `vega_lite` targets Vega-Lite v5; copy examples from the v5 docs, not older Vega-Lite.

## Integration Notes (Livebook/Kino)
- The "Chart" smart cell is the fastest path from a bound DataFrame to a spec; convert to code to refine.
- Pairs naturally with `Kino.DataTable` (inspect rows) and Explorer (shape data) in the same notebook.
- The emitted spec is plain Vega-Lite JSON — you can lift a chart out of Livebook into a web page unchanged.

## Best For / Avoid For
`livebook`, `elixir`, `declarative-charts`, `streaming-data`, `data-exploration`, `dashboards`
- **Best for**: exploratory analysis in Elixir notebooks, live/streaming plots, teaching, reproducible report charts, anything where a portable Vega-Lite spec is the deliverable.
- **Avoid for**: pixel-perfect print graphics, 3D, very large raw scatterplots (aggregate first), or non-Livebook runtime UIs (emit the JSON and use vega-embed instead).

## See Also
- [kino-plotly.md](kino-plotly.md) — imperative/scientific + 3D charts in Livebook
- [kino-datatable.md](kino-datatable.md) — tabular inspection to pair with charts
- [kino-js.md](kino-js.md) — build a fully custom chart widget when Vega-Lite can't express it
- [vega-lite.md](vega-lite.md) / [vega.md](vega.md) — the underlying JS spec language
- `./kino-vegalite/use-case/data-visualization.md`, `./kino-vegalite/use-case/elixir-livebook-components.md`
- `../use-case/elixir-livebook-components.md`, `../use-case/data-visualization.md`
