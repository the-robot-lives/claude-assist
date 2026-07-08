# Highcharts

## What
Highcharts is a commercial-grade interactive JavaScript charting library for the browser, with extensive customization, financial/stock charts, and built-in export capabilities.

## How
- The LLM emits browser JavaScript: `Highcharts.chart('container', { chart, title, xAxis, yAxis, series, plotOptions })`.
- Rendered by loading `https://code.highcharts.com/highcharts.js` (plus modules like `exporting.js`) or installing `highcharts` via npm, then calling `Highcharts.chart()` on a container element. Node.js server-side rendering is supported.
- Final artifact: an interactive chart with export to PDF/SVG/PNG; the Boost module enables 1M+ point rendering.

## Why
- Reach for Highcharts for stock charts with technical indicators, 3D/polar projections, very large datasets (Boost for >10k points), and built-in PDF/SVG/PNG export — strong for financial and production dashboards.
- Tradeoffs: a commercial license is required for commercial use; enable lazy loading and Boost for heavy dashboards.
- Versus Apache ECharts it is comparably capable but paid; versus Chart.js it is substantially more powerful and customizable.

## Source
- Solution reference: `fim/solution/highcharts.md`
