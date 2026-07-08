# Highcharts — Commercial-grade interactive SVG charts

Highcharts is a mature JavaScript charting library rendering interactive SVG charts. A chart is one config object passed to `Highcharts.chart(container, options)`, structured as `chart` / `title` / `xAxis` / `yAxis` / `series` / `plotOptions`. It offers 20+ series types plus add-on modules (Highstock for finance, Highmaps for geo, boost for big data) and built-in export. It is free for non-commercial use; commercial deployment requires a license.

**Current Version**: 11.x (current major)  **License**: Proprietary — free for personal/non-profit/eval; paid for commercial use  **Runtime**: browser, SVG

## Official Resources & Documentation
- Docs: https://www.highcharts.com/docs
- API reference: https://api.highcharts.com/highcharts/
- Demos: https://www.highcharts.com/demo
- npm: https://www.npmjs.com/package/highcharts
- Licensing: https://shop.highcharts.com/

## Installation & Setup
### CDN
```html
<script src="https://code.highcharts.com/highcharts.js"></script>
<script src="https://code.highcharts.com/modules/exporting.js"></script>
<script src="https://code.highcharts.com/modules/accessibility.js"></script>
```
### npm / ESM
```bash
npm install highcharts
```
```javascript
import Highcharts from 'highcharts';
import 'highcharts/modules/exporting';
import 'highcharts/modules/boost';        // large datasets
// Stock/Maps builds:
import Highcharts from 'highcharts/highstock';
import Highcharts from 'highcharts/highmaps';
```

## Core API Reference
```javascript
const chart = Highcharts.chart('container', {
  chart: { type: 'spline', zoomType: 'x', backgroundColor: 'transparent' },
  title: { text: 'Temperature Trends' },
  subtitle: { text: 'Source: sensors' },
  xAxis: { categories: ['Jan','Feb','Mar','Apr','May'], title: { text: 'Month' } },
  yAxis: { title: { text: '°C' }, min: 0, gridLineColor: '#eee' },
  legend: { align: 'center', verticalAlign: 'bottom', layout: 'horizontal' },
  tooltip: { shared: true, valueSuffix: ' °C' },
  plotOptions: { series: { marker: { enabled: true }, animation: { duration: 800 } } },
  series: [
    { name: '2023', data: [7.0, 6.9, 9.5, 14.5, 18.2] },
    { name: '2024', data: [3.9, 4.2, 5.7, 8.5, 11.9] }
  ],
  credits: { enabled: false }
});
chart.update({ ... });          // patch config
chart.addSeries({ ... });
chart.series[0].setData([...]);
chart.exportChart({ type: 'image/png' });
chart.destroy();
```
Series data forms: `[y, y, y]`, `[[x,y],...]`, `[{x,y,name,color},...]`, and for finance `[[timestamp, open, high, low, close],...]`.

## Series / Chart Types
- **Basic**: `line`, `spline`, `area`, `areaspline`, `column`, `bar`, `pie`, `scatter`, `bubble`.
- **Stacked/percent**: any column/area with `plotOptions.series.stacking: 'normal' | 'percent'`.
- **Statistical**: `boxplot`, `errorbar`, `histogram`, `bellcurve`, `scatter3d`.
- **Advanced/other modules**: `heatmap`, `treemap`, `sunburst`, `sankey`, `dependencywheel`, `networkgraph`, `packedbubble`, `streamgraph`, `funnel`, `pyramid`, `gauge`, `solidgauge`, `waterfall`, `polar`/radar (via `chart.polar:true`), `wordcloud`, `venn`, `timeline`, `xrange` (Gantt-ish), `arcdiagram`, `organization`.
- **Highstock (finance)**: `candlestick`, `ohlc`, `hlc`, `flags`, plus navigator/scrollbar/range-selector and 40+ technical indicators (`sma`, `ema`, `rsi`, `macd`, `bb`).
- **Highmaps**: `map`, `mapline`, `mappoint`, `mapbubble`, `heatmap` on GeoJSON/TopoJSON.

## Axes
```javascript
xAxis: {
  type: 'datetime',                 // 'linear'|'logarithmic'|'datetime'|'category'
  labels: { format: '{value:%b %Y}', rotation: -45 },
  plotBands: [{ from: 3, to: 5, color: 'rgba(200,0,0,0.1)' }],
  plotLines: [{ value: 4, color: 'red', dashStyle: 'Dash', width: 2 }],
  crosshair: true
},
yAxis: [
  { title: { text: 'Primary' }, min: 0 },
  { title: { text: 'Secondary' }, opposite: true }   // dual axis; series set yAxis:1
]
```

## Legends, Tooltips, Interactivity
```javascript
tooltip: {
  shared: true, useHTML: true, valuePrefix: '$', valueDecimals: 2,
  headerFormat: '<b>{point.key}</b><br/>',
  pointFormat: '<span style="color:{series.color}">●</span> {series.name}: {point.y}<br/>'
},
legend: { enabled: true, itemStyle: { color: '#333' }, layout: 'vertical', align: 'right' },
plotOptions: { series: { point: { events: { click: function(){ /* this.y */ } } },
                         cursor: 'pointer' } }
```

## How-To

### How to set colors / palette / theme
```javascript
// 1) Global palette (series cycle through it)
Highcharts.setOptions({ colors: ['#4e79a7','#f28e2b','#e15759','#76b7b2','#59a14f'] });

// 2) Per-series color
series: [{ name:'A', data:[...], color:'#4e79a7' }]

// 3) Per-point color (columns/pie)
series:[{ data:[{y:5,color:'#59a14f'},{y:-3,color:'#e15759'}] }]

// 4) Gradient fill
color: { linearGradient:{x1:0,y1:0,x2:0,y2:1},
         stops:[[0,'#7cb5ec'],[1,'rgba(124,181,236,0)']] }

// 5) Full dark theme
Highcharts.setOptions({
  chart: { backgroundColor: '#111' },
  title: { style: { color: '#e5e7eb' } },
  xAxis: { gridLineColor:'#333', labels:{style:{color:'#ccc'}}, lineColor:'#444' },
  yAxis: { gridLineColor:'#333', labels:{style:{color:'#ccc'}} },
  legend: { itemStyle:{color:'#ccc'} }
});
```
Highcharts ships theme files (`highcharts/themes/dark-unica`, `grid-light`, `sand-signika`, `brand-dark`) — import and they call `setOptions` for you.

### How to build a stock chart with indicators
```javascript
import Highcharts from 'highcharts/highstock';
import 'highcharts/indicators/indicators-all';
Highcharts.stockChart('container', {
  rangeSelector: { selected: 1 },
  series: [
    { type: 'candlestick', id: 'ohlc', name: 'AAPL', data: ohlcData },
    { type: 'sma', linkedTo: 'ohlc', params: { period: 20 } },
    { type: 'volume', data: volData, yAxis: 1 }
  ],
  yAxis: [{ height: '70%' }, { top: '72%', height: '28%' }]
});
```

### How to handle 1M+ points (boost)
```javascript
import 'highcharts/modules/boost';
Highcharts.chart('c', {
  boost: { useGPUTranslations: true, seriesThreshold: 1 },
  series: [{ type: 'scatter', data: bigArray, boostThreshold: 1, marker: { radius: 1 } }]
});
```

### How to export to PNG/SVG/PDF
```javascript
import 'highcharts/modules/exporting';
import 'highcharts/modules/offline-exporting';   // client-side, no server round-trip
chart.exportChartLocal({ type: 'application/pdf', filename: 'report' });
```

## Do's and Don'ts

### ✅ Do
- Get a commercial license before shipping to production — usage is metered by dev seats.
- Use `boost` for >5–10k points and drop markers (`marker.radius:1`).
- Use `Highcharts.setOptions` for app-wide palette/theme once at startup.
- Prefer `offline-exporting` so chart images never leave the client.

### ❌ Don't
- Don't use the default server-side export (`export.highcharts.com`) for confidential data — it POSTs your chart config to Highsoft. Use `offline-exporting`.
- Don't forget to import the module for a feature (heatmap, treemap, exporting, boost) — the type silently won't render.
- Don't animate huge boosted datasets — disable animation for perf.
- Don't remove the credits label unless your license permits it.

## Styling, Theming & Customization
- Global via `Highcharts.setOptions({...})`; per-chart via the config; per-series/per-point via `color`, `dashStyle`, `marker`, `dataLabels`.
- `plotOptions.<type>` sets defaults for all series of a type; `plotOptions.series` for all.
- `dataLabels: { enabled:true, format:'{point.y:.1f}', style:{...} }`.
- CSS styled-mode: build with `styledMode:true` and style via CSS classes (`.highcharts-series`, `.highcharts-color-0`).

## Advanced Features
- **Highstock**: navigator, scrollbar, range selector, technical indicators, annotations, price flags.
- **Highmaps**: choropleth/bubble maps over GeoJSON/TopoJSON with projections.
- **Boost module**: WebGL-accelerated rendering for millions of points.
- **Accessibility module**: keyboard nav, ARIA, screen-reader descriptions, sonification (`sonification` module).
- **Annotations module**: draggable labels, shapes, fibonacci, measure tools.
- **Server-side rendering**: `highcharts-export-server` (Node) for PDF/PNG generation.
- **Framework wrappers**: `highcharts-react-official`, `highcharts-vue`, `highcharts-angular`.

## Integration Notes
- **React**: `highcharts-react-official` — `<HighchartsReact highcharts={Highcharts} options={options} />`; it diffs and re-renders on options change.
- **Vue**: `highcharts-vue`; **Angular**: `highcharts-angular`.
- **Server-side**: `highcharts-export-server` (Node/Puppeteer) renders PNG/PDF/SVG headless for reports/emails.
- **Modules are additive**: import `modules/exporting`, `modules/accessibility`, `modules/boost`, `modules/heatmap`, `indicators/indicators-all` as needed — each registers its features onto the `Highcharts` object.

### How to add threshold plot lines and annotations
```javascript
yAxis: {
  plotLines: [{ value: 100, color: 'red', width: 2, dashStyle: 'ShortDash',
                label: { text: 'Target' } }]
}
```

## Common Pitfalls & Troubleshooting
- Series type "not found" → missing module import (e.g. `modules/heatmap`).
- License warning/watermark → you're on a build that expects a license key in production.
- Blank chart → container has no height, or data timestamps aren't ms since epoch for datetime axes.
- Export sends data externally → switch to `offline-exporting`.
- Dates off by timezone → set `time: { useUTC: true|false }` globally.

## Best For / Avoid For
`financial-stock-charts`, `enterprise-dashboards`, `technical-indicators`, `1M+-points`, `accessible-charts`, `maps` — choose Highcharts.
Avoid for: `zero-budget-commercial` (use Chart.js/ECharts), `fully-custom-visuals` (D3/Vega), `3D-scientific` (Plotly).

## See Also
- `chart_js.md` — free canvas alternative
- `plotly_js.md` — open-source scientific/3D
- `google-charts.md` — free, Google-hosted
- `../use-case/data-visualization.md`
