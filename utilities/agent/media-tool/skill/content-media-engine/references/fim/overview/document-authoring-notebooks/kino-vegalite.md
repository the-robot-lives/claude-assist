# Kino.VegaLite

## What
Kino.VegaLite provides interactive Vega-Lite visualizations for Elixir LiveBook, enabling declarative data visualization using the Vega-Lite specification language directly in notebook cells.

## How
- The LLM emits Elixir: `VegaLite.new(...)` piped through `data_from_values/2`, `mark/2`, and `encode_field/4` to build a chart spec.
- Rendered by evaluating the LiveBook cell after `Mix.install([{:kino_vega_lite, "~> 0.1.11"}, {:kino, "~> 0.12.0"}])`; `Kino.animate` supports streaming data.
- Final artifact: an interactive chart (pan/zoom/hover tooltips) rendered in a LiveBook cell.

## Why
- Reach for Kino.VegaLite for declarative statistical visualization in LiveBook — data exploration, prototyping, teaching, notebook reports, and real-time streaming charts — with the full Vega-Lite spec and built-in data transformations.
- Tradeoffs: LiveBook-only, limited options for embedding outside notebooks, Vega-Lite spec knowledge needed for advanced use, and large datasets can impact responsiveness.
- Within the Kino family it is the declarative statistical-charting option (the Elixir binding to Vega-Lite); Kino.Plotly covers 3D/scientific plotting. The nested `use-case/` detail covers data-visualization and Livebook-component scenarios.

## Source
- Solution reference: `fim/solution/kino-vegalite.md`
- Nested use-case detail: `fim/solution/kino-vegalite/use-case/data-visualization.md`, `fim/solution/kino-vegalite/use-case/elixir-livebook-components.md`
