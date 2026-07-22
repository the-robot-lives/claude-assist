# Apache ECharts

## What
Apache ECharts is an open-source JavaScript charting library (Apache Software Foundation) that produces enterprise-grade interactive data visualizations in the browser. It renders through dual Canvas and SVG engines and ships 20+ chart types — from basic line/bar to heatmaps, treemaps, sunburst, parallel coordinates, sankey, and geographic maps.

## How
- The LLM emits browser JavaScript: an `option` configuration object passed to an initialized chart instance.
- Rendered by loading the library (CDN `<script src="https://cdn.jsdelivr.net/npm/echarts@5.4.3/dist/echarts.min.js">` or npm), calling `echarts.init(dom)`, then `chart.setOption(option)`. Canvas is the default engine; SVG can be selected for crisp/print output.
- Final artifact: an interactive chart in a DOM container (Canvas or SVG); server-side rendering is also supported.

## Why
- Reach for ECharts when you need breadth of chart types, high performance on large datasets (GPU acceleration, data sampling, progressive rendering), and deep theming/interaction in one library — good for complex analytical dashboards.
- Tradeoffs: extensive configuration has a steep learning curve, the full bundle is relatively large (~1MB minified) so tree-shaking matters, CSS has limited effect on chart internals, and responsive design needs manual breakpoint handling.
- Versus Chart.js it is far more capable but heavier; versus Highcharts it is comparably feature-rich but fully open-source (no commercial license).

## Source
- Solution reference: `fim/solution/apache-echarts.md`
