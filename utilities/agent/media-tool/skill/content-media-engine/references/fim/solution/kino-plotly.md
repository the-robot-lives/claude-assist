# Kino.Plotly — Plotly.js scientific & 3D charts in Elixir Livebook

Kino.Plotly renders Plotly.js figures inside Livebook cells from Elixir. Unlike the declarative Vega-Lite DSL, Plotly uses an **imperative figure model**: you assemble a list of *trace* maps (each a chart series with a `type`) plus a `layout` map, and Plotly draws it. This is the go-to Kino widget for 3D surfaces/scatter, heatmaps, contours, and statistical plots. It runs only inside Livebook/Kino; the figure itself is plain Plotly JSON.

**Current Version**: `kino_plotly ~> 0.1` (community), Plotly.js v2 in-browser  **License**: check the package (MIT-class)  **Runtime**: Livebook / Kino; ships the Plotly.js bundle to the browser

> Accuracy note: `kino_plotly` is a community package, not an official `livebook-dev` core lib. If it is unavailable, use the **Kino.JS fallback** at the bottom of this doc, which embeds Plotly.js directly and is guaranteed to work in any Kino runtime. Prefer the fallback when you need a version you control.

## Official Resources & Documentation
- Plotly.js reference (traces + layout): https://plotly.com/javascript/reference/
- Plotly.js chart gallery: https://plotly.com/javascript/
- kino_plotly (community): https://hex.pm/packages/kino_plotly
- Kino.JS (fallback path) docs: https://hexdocs.pm/kino/Kino.JS.html
- Livebook: https://livebook.dev/

## Installation & Setup
### Mix / Livebook setup cell
```elixir
Mix.install([
  {:kino_plotly, "~> 0.1"},
  {:kino, "~> 0.12"}
])
```
Fallback path (no third-party wrapper) needs only `{:kino, "~> 0.12"}`.

## Core Syntax / API Reference

### The figure model: traces + layout
A Plotly figure is `{data, layout}` where `data` is a **list of trace maps**. Each trace's `type` selects the chart; other keys are that trace's data/style.
```elixir
trace = %{
  type: "scatter",         # trace type
  mode: "lines+markers",   # scatter sub-mode
  x: [1, 2, 3, 4],
  y: [10, 15, 13, 17],
  name: "series A",
  marker: %{color: "#22c55e", size: 8}
}

layout = %{
  title: "Example",
  xaxis: %{title: "X"},
  yaxis: %{title: "Y"}
}

Kino.Plotly.new([trace], layout)
```

### Common trace `type` values
- **2D**: `"scatter"` (line/marker/area via `mode` + `fill`), `"bar"`, `"histogram"`, `"box"`, `"violin"`, `"heatmap"`, `"contour"`, `"pie"`.
- **3D**: `"surface"`, `"scatter3d"`, `"mesh3d"`, `"cone"`, `"streamtube"`.
- **Maps/finance**: `"scattergeo"`, `"choropleth"`, `"candlestick"`, `"ohlc"`.
- **Stat/other**: `"histogram2d"`, `"histogram2dcontour"`, `"scatterpolar"`, `"sunburst"`, `"treemap"`.

### Key trace fields by family
```elixir
# line / scatter
%{type: "scatter", mode: "lines", x: xs, y: ys, line: %{width: 2, dash: "dot"}}
# 3d surface (z is a 2D matrix, i.e. list of rows)
%{type: "surface", z: matrix, colorscale: "Viridis"}
# 3d scatter
%{type: "scatter3d", mode: "markers", x: xs, y: ys, z: zs, marker: %{size: 4}}
# heatmap
%{type: "heatmap", z: matrix, x: cols, y: rows, colorscale: "RdBu"}
# bar
%{type: "bar", x: labels, y: values, marker: %{color: colors}}
```

### `layout` essentials
```elixir
layout = %{
  title: "My Figure",
  width: 700, height: 500,
  margin: %{l: 60, r: 20, t: 50, b: 50},
  xaxis: %{title: "time", type: "linear"},   # or "log", "date", "category"
  yaxis: %{title: "value"},
  legend: %{orientation: "h"},
  # 3D charts use `scene`, not xaxis/yaxis:
  scene: %{
    xaxis: %{title: "X"},
    yaxis: %{title: "Y"},
    zaxis: %{title: "Z"},
    camera: %{eye: %{x: 1.6, y: 1.6, z: 0.8}}
  }
}
```

### The `z` matrix for surfaces/heatmaps
`z` is a list of rows (a 2D list). Build it from a flat list with `Enum.chunk_every/2`:
```elixir
x = 1..20 |> Enum.to_list()
y = 1..20 |> Enum.to_list()
z =
  for j <- y do
    for i <- x, do: :math.sin(i / 3) * :math.cos(j / 3)
  end

Kino.Plotly.new(
  [%{type: "surface", z: z, colorscale: "Viridis"}],
  %{title: "sin·cos surface", scene: %{zaxis: %{title: "amplitude"}}}
)
```

## Chart Types you can produce
Line, multi-series line, filled area, bar/grouped/stacked bar, histogram, box plot, violin plot, 2D scatter/bubble, heatmap, contour, pie/donut, 3D surface, 3D scatter, 3D mesh, cone/streamtube vector fields, polar plots, sunburst/treemap hierarchies, geographic scatter/choropleth, and financial candlestick/OHLC.

## How-To (worked recipes)

### How to add colors / a colorscale / a theme
Per-trace color for categorical data, a `colorscale` for continuous z, and `layout.template`/colors for the whole figure:
```elixir
trace = %{
  type: "bar",
  x: ["A", "B", "C", "D"],
  y: [30, 55, 43, 91],
  marker: %{color: ["#2563eb", "#16a34a", "#f59e0b", "#dc2626"]}  # per-bar colors
}

layout = %{
  title: "Colored bars (dark)",
  paper_bgcolor: "#0f172a",     # outside plot
  plot_bgcolor: "#0f172a",      # plotting area
  font: %{color: "#e2e8f0"},
  xaxis: %{gridcolor: "#334155"},
  yaxis: %{gridcolor: "#334155"}
}

Kino.Plotly.new([trace], layout)
```
Continuous data: set `colorscale: "Viridis" | "RdBu" | "Cividis" | "Hot"` on the trace and `showscale: true` for a color bar. There is no Elixir theme object — dark mode is `paper_bgcolor`/`plot_bgcolor`/`font` + axis `gridcolor`.

### How to build a 3D scatter you can rotate
```elixir
n = 300
xs = for _ <- 1..n, do: :rand.normal()
ys = for _ <- 1..n, do: :rand.normal()
zs = Enum.zip_with(xs, ys, fn a, b -> a * b + :rand.normal() * 0.2 end)

Kino.Plotly.new(
  [%{type: "scatter3d", mode: "markers", x: xs, y: ys, z: zs,
     marker: %{size: 3, color: zs, colorscale: "Viridis"}}],
  %{title: "3D cloud", scene: %{camera: %{eye: %{x: 1.8, y: 1.8, z: 1.0}}}}
)
```

### How to overlay multiple series
Pass more than one trace; each gets its own `name` in the legend:
```elixir
Kino.Plotly.new(
  [
    %{type: "scatter", mode: "lines", name: "actual", x: xs, y: actual},
    %{type: "scatter", mode: "lines", name: "forecast",
      x: xs, y: forecast, line: %{dash: "dash"}}
  ],
  %{title: "Actual vs forecast", legend: %{orientation: "h"}}
)
```

### How to make a heatmap from a matrix
```elixir
z = [[1, 20, 30], [20, 1, 60], [30, 60, 1]]
Kino.Plotly.new(
  [%{type: "heatmap", z: z, x: ["a", "b", "c"], y: ["a", "b", "c"],
     colorscale: "RdBu", reversescale: true}],
  %{title: "Correlation"}
)
```

### How to render Plotly without the wrapper (Kino.JS fallback)
Guaranteed-portable: embed Plotly.js and call `Plotly.newPlot` in a custom widget.
```elixir
defmodule PlotlyFig do
  use Kino.JS

  def new(data, layout \\ %{}) do
    Kino.JS.new(__MODULE__, %{data: data, layout: layout})
  end

  asset "main.js" do
    """
    export async function init(ctx, %{data, layout}) {
      await ctx.importJS("https://cdn.plot.ly/plotly-2.35.2.min.js");
      const el = document.createElement("div");
      ctx.root.appendChild(el);
      Plotly.newPlot(el, data, layout, {responsive: true});
    }
    """
  end
end

PlotlyFig.new(
  [%{type: "scatter", mode: "lines", x: [1, 2, 3], y: [2, 6, 4]}],
  %{title: "via Kino.JS"}
)
```

## Do's and Don'ts
### ✅ Do
- Model every chart as a **list of trace maps** — even single-series charts.
- Use string trace `type`s exactly as Plotly.js spells them (`"scatter3d"`, not `:scatter_3d`).
- Put 3D axes under `layout.scene`, 2D axes under `layout.xaxis`/`yaxis`.
- Build `z` matrices with `Enum.chunk_every/2` and verify row/column orientation.
- Prefer the Kino.JS fallback when you need a specific Plotly.js version or offline reliability.

### ❌ Don't
- Don't put `xaxis`/`yaxis` on a 3D chart expecting them to affect the scene — they're ignored; use `scene`.
- Don't send megabyte-scale traces — Plotly.js serializes and renders in the browser; downsample first.
- Don't mix incompatible trace types in one figure (e.g. `surface` + `bar`) unless you deliberately use subplots.
- Don't assume atom vs string keys are interchangeable in the final JSON — keep trace keys consistent (atoms serialize fine; be uniform).
- Don't rely on `Kino.Plotly` being present in every environment — have the fallback ready.

## Styling, Theming & Customization
- **Colors**: per-point/`marker.color` (list or single), `line.color`, or a continuous `colorscale` + `showscale`.
- **Colorscales**: `Viridis`, `Cividis`, `RdBu`, `Hot`, `Jet`, `Portland`, `YlGnBu`, or a custom `[[0,"#000"],[1,"#fff"]]` list.
- **Dark mode**: `paper_bgcolor`, `plot_bgcolor`, `font.color`, axis `gridcolor`/`zerolinecolor`.
- **Layout**: `margin`, `width`/`height` (or omit for responsive), `legend.orientation`, `hovermode`, `annotations`, `shapes`.
- **Axes**: `type: "log" | "date" | "category"`, `range`, `tickformat`, `dtick`.

## Advanced Features
- **Subplots**: assign traces to `xaxis: "x2"`, `yaxis: "y2"` and declare `xaxis2`/`yaxis2` domains in layout for grids of plots.
- **Interactivity**: pan/zoom/rotate, hover tooltips, legend toggling, and the modebar (download PNG, box/lasso select) are built in.
- **Animations**: Plotly frames are possible via the JS fallback (`Plotly.animate`); the Elixir wrapper is best for static-then-rebuild updates.
- **Export**: the modebar "Download plot as PNG" button works client-side; the figure JSON is portable to any Plotly runtime.

## Common Pitfalls & Troubleshooting
- **3D chart looks flat / axes wrong**: you configured `layout.xaxis` instead of `layout.scene.xaxis`.
- **Surface renders transposed**: your `z` rows/columns are swapped — check the `for` nesting order.
- **Nothing renders**: an unknown `type` string or a trace that isn't in a list. Wrap single traces in `[trace]`.
- **Huge/slow notebook**: the Plotly.js bundle plus a large trace payload; downsample and consider the CDN fallback so the bundle is cached.
- **Wrapper missing**: `Kino.Plotly` undefined → use the Kino.JS fallback.
- **Colors ignored**: `marker.color` list length must match the data length; a scalar colors all points.

## Integration Notes (Livebook/Kino)
- Pairs with Explorer/Nx for numeric work: compute arrays in Elixir, hand `x`/`y`/`z` lists to a trace.
- Use `Kino.DataTable` to inspect the rows behind a chart in the same notebook.
- The Kino.JS fallback is the same mechanism Livebook uses for custom widgets — see kino-js.md.

## Best For / Avoid For
`livebook`, `elixir`, `3d`, `scientific-viz`, `heatmaps`, `statistical-charts`, `imperative-figures`
- **Best for**: 3D surfaces/scatter, heatmaps/contours, statistical plots (box/violin), scientific and engineering data exploration in Elixir.
- **Avoid for**: when a concise declarative spec suffices (use Kino.VegaLite), print-quality static figures, or shipping to non-Livebook UIs without the JSON-embed step.

## See Also
- [kino-vegalite.md](kino-vegalite.md) — declarative charts; prefer for standard 2D statistical graphics
- [kino-js.md](kino-js.md) — the custom-widget mechanism behind the Plotly fallback
- [kino-datatable.md](kino-datatable.md) — inspect the underlying data
- [plotly_js.md](plotly_js.md) / [plotly-python.md](plotly-python.md) — Plotly in other runtimes
- `../use-case/elixir-livebook-components.md`, `../use-case/data-visualization.md`
