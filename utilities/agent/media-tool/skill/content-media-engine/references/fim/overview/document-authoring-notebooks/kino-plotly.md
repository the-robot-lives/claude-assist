# Kino.Plotly

## What
Kino.Plotly brings Plotly.js charts to Elixir LiveBook, providing interactive scientific visualizations — including 3D plotting — directly in notebook cells.

## How
- The LLM emits Elixir: build `data` and `layout` maps (e.g. a `type: "surface"` 3D plot with a scene config) and pass them to `Kino.Plotly.new([data], layout)`.
- Rendered by evaluating the LiveBook cell after `Mix.install([{:kino_plotly, "~> 0.1.0"}, {:kino, "~> 0.12.0"}])`; `Kino.animate` supports real-time updates.
- Final artifact: an interactive chart (3D rotation, zoom, hover) rendered in a LiveBook cell.

## Why
- Reach for Kino.Plotly for scientific visualization and 3D plotting in LiveBook — surface/scatter3d/mesh plots, heatmaps, contours, and interactive data apps — with access to the Plotly.js feature set.
- Tradeoffs: LiveBook-only, the Plotly.js bundle increases notebook size, less flexible than pure Plotly.js, and visualizations are notebook-bound (export constraints).
- Within the Kino family it is the scientific/3D charting option; Kino.VegaLite covers declarative statistical charts, Kino.DataTable covers tables.

## Source
- Solution reference: `fim/solution/kino-plotly.md`
