# Google Charts

## What
Google Charts is a free browser-based charting library backed by Google's data-visualization stack. It offers common chart types plus GeoCharts for maps, and timeline/Gantt charts, with Material Design styling.

## How
- The LLM emits browser JavaScript: build a `google.visualization.DataTable` (e.g. via `arrayToDataTable`), an `options` object, then instantiate a chart type (e.g. `PieChart`) and call `chart.draw(data, options)`.
- Rendered by loading `https://www.gstatic.com/charts/loader.js`, calling `google.charts.load('current', {packages:['corechart']})`, and running the draw routine from `setOnLoadCallback`.
- Final artifact: an interactive chart in a DOM container, with optional real-time data updates.

## Why
- Reach for Google Charts when you want direct Google Sheets integration, map/GeoChart and timeline/Gantt visualizations, and zero cost with familiar Material styling.
- Tradeoffs: depends on Google's hosted loader (external dependency), and responsive sizing must be wired up manually on window resize; DataTables are the expected input structure.
- Versus Chart.js it adds geo/timeline breadth and Sheets integration; versus Highcharts it is free but less deeply customizable.

## Source
- Solution reference: `fim/solution/google-charts.md`
