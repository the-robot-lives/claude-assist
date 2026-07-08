# Vega-Lite

## What
Vega-Lite is a concise declarative JSON grammar for interactive visualizations in the browser. It expresses charts as `mark` + `encoding` and compiles to full Vega, with built-in statistical transforms.

## How
- The LLM emits a compact Vega-Lite JSON spec (`$schema`, `data`, `mark`, `encoding`).
- Rendered by installing `vega-lite` + `vega-embed` (or loading vega/vega-lite/vega-embed from CDN) and calling `vegaEmbed('#vis', spec)`.
- Final artifact: an interactive chart rendered via SVG/Canvas from the spec.

## Why
- Reach for Vega-Lite for statistical charts, dashboards, exploratory data analysis, and academic figures — its terse syntax auto-generates scales, legends, and responsive layout, with built-in regression/density/binning and composable faceting/layering.
- Tradeoffs: less customizable than D3.js, JSON-only specs can still be verbose, and performance suffers on large datasets (>50k points).
- Versus Vega it is much more concise (it compiles down to Vega); it is also the grammar that Python's Altair generates under the hood.

## Source
- Solution reference: `fim/solution/vega-lite.md`
