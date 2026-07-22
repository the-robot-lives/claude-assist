# Plotly.js

## What
Plotly.js is a high-level JavaScript charting library for scientific, statistical, and 3D visualizations in the browser. It offers 100+ chart types and is interactive by default (zoom, pan, hover), with WebGL rendering for performance.

## How
- The LLM emits browser JavaScript: arrays of `data` traces plus a `layout` object passed to `Plotly.newPlot('div', data, layout)`.
- Rendered by installing `plotly.js-dist` (v2.35.2 via npm) or loading `https://cdn.plot.ly/plotly-2.35.2.min.js`, then calling `Plotly.newPlot` against a target `<div>`.
- Final artifact: an interactive chart in a DOM container; exports to PNG/SVG/JSON.

## Why
- Reach for Plotly.js for scientific plots, built-in 3D surface/mesh visualizations, statistical charts, financial data, heatmaps, and contour plots — 3D and interactivity come out of the box.
- Tradeoffs: large file size (3MB+), some features require a commercial license, less customizable than D3, and limited animation capabilities.
- Versus Chart.js it adds 3D, WebGL, and far more chart types at the cost of bundle size; the nested `use-case/` detail covers both 3D-graphics and standard data-visualization scenarios.

## Source
- Solution reference: `fim/solution/plotly_js.md`
- Nested use-case detail: `fim/solution/plotly_js/use-case/3d-graphics.md`, `fim/solution/plotly_js/use-case/data-visualization.md`
