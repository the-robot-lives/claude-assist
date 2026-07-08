# Chart.js

## What
Chart.js is a simple, flexible JavaScript charting library that renders to an HTML5 Canvas in the browser. It covers 8 basic chart types with good default styling and is lightweight (~60KB gzipped).

## How
- The LLM emits browser JavaScript: `new Chart(ctx, { type, data, options })` against a canvas 2D context.
- Rendered by installing `chart.js` (v4.4.4 via npm) or loading the UMD bundle from CDN (`chart.umd.min.js`), then constructing a `Chart` on a `<canvas>` element. `responsive: true` / `maintainAspectRatio: false` control sizing.
- Final artifact: an interactive, responsive chart drawn on a Canvas element.

## Why
- Reach for Chart.js for simple dashboards, responsive/mobile charts, quick prototypes, and basic analytics — it is easy to learn with sensible defaults.
- Tradeoffs: only 8 basic chart types, no 3D, Canvas-only (no SVG output), and far less flexible than D3.
- Versus Apache ECharts / Highcharts it trades breadth and power for simplicity and small size; versus D3 it trades control for ease of use.

## Source
- Solution reference: `fim/solution/chart_js.md`
