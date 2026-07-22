# Chart.js — Canvas-based JavaScript charting library

Chart.js renders responsive 2D charts to an HTML `<canvas>` element. It ships eight built-in chart types, a plugin architecture, tree-shakeable modules, and animated, interactive defaults. It is the go-to for dashboards and product analytics where you want good-looking charts fast without D3-level effort.

**Current Version**: 4.4.x (current major)  **License**: MIT  **Bundle**: ~65KB gzipped (full UMD); much smaller when tree-shaken

## Official Resources & Documentation
- Docs: https://www.chartjs.org/docs/latest/
- Samples: https://www.chartjs.org/docs/latest/samples/
- GitHub: https://github.com/chartjs/Chart.js
- npm: https://www.npmjs.com/package/chart.js
- Awesome plugins: https://github.com/chartjs/awesome
- Datalabels plugin: https://chartjs-plugin-datalabels.netlify.app/

## Installation & Setup

### Package manager
```bash
npm install chart.js       # v4.4.x
# adapters for time scales:
npm install chartjs-adapter-date-fns date-fns
```

### CDN (auto-registers everything)
```html
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
```

### ESM import — full auto-registration
```javascript
import Chart from 'chart.js/auto';   // registers all controllers, elements, scales, plugins
```

### ESM import — tree-shaken (production)
```javascript
import {
  Chart, LineController, LineElement, PointElement,
  LinearScale, CategoryScale, Legend, Tooltip, Filler
} from 'chart.js';
Chart.register(LineController, LineElement, PointElement,
  LinearScale, CategoryScale, Legend, Tooltip, Filler);
```
If a chart renders blank with `"category" is not a registered scale`, you tree-shook but forgot to `Chart.register(...)` the scale/controller.

## Core API Reference

### Constructor
```javascript
const chart = new Chart(ctxOrCanvas, config);
// config = { type, data, options, plugins }
chart.update();      // re-render after mutating data/options
chart.resize();      // manual resize
chart.destroy();     // free canvas + listeners (REQUIRED in SPAs)
chart.toBase64Image('image/png', 1.0);  // export
```

### Config skeleton
```javascript
const config = {
  type: 'bar',
  data: {
    labels: ['Q1', 'Q2', 'Q3', 'Q4'],
    datasets: [{
      label: 'Revenue',
      data: [120, 190, 130, 170],
      backgroundColor: '#4e79a7',
      borderColor: '#4e79a7',
      borderWidth: 1
    }]
  },
  options: { /* scales, plugins, interaction, animation */ }
};
```

### Dataset shapes
```javascript
// Parallel arrays (data indexes labels)
data: [10, 20, 30]
// Object points (parsing keys)
data: [{x: 1, y: 10}, {x: 2, y: 15}]
// Custom keys via parsing
datasets: [{ data: rows, parsing: { xAxisKey: 'date', yAxisKey: 'sales' } }]
// Bubble: {x, y, r};  Scatter: {x, y}
```

## Chart Types (the eight built-ins)
- `line` — line/area; `fill`, `tension` (spline), `stepped`, `spanGaps`
- `bar` — vertical/horizontal (`indexAxis: 'y'`), stacked, grouped, floating (`data: [[min,max]]`)
- `pie` / `doughnut` — `cutout` controls hole size
- `radar` — multi-axis polygon with `r` radial scale
- `polarArea` — radial bars, equal angles
- `scatter` — XY point cloud (line type with `showLine:false`)
- `bubble` — XY plus radius `r`
- Mixed charts: give each dataset its own `type` and share `options` (e.g., bar + line combo).

```javascript
new Chart(ctx, {
  data: {
    labels,
    datasets: [
      { type: 'bar',  label: 'Volume', data: vol,  yAxisID: 'y' },
      { type: 'line', label: 'Price',  data: price, yAxisID: 'y1' }
    ]
  },
  options: { scales: { y: {position:'left'}, y1: {position:'right', grid:{drawOnChartArea:false}} } }
});
```

## Scales
Scale types: `linear`, `logarithmic`, `category`, `time`, `timeseries`, `radialLinear`.
```javascript
options: {
  scales: {
    x: { type: 'time', time: { unit: 'day' }, title: { display: true, text: 'Date' } },
    y: {
      type: 'linear', beginAtZero: true, min: 0, max: 100, suggestedMax: 120,
      ticks: { stepSize: 20, callback: v => `${v}%` },
      grid: { color: 'rgba(0,0,0,0.06)' },
      stacked: false
    }
  }
}
```
Time scales require a date adapter (`chartjs-adapter-date-fns` or `-luxon`). Without it, time axes throw.

## Axes, Legends, Tooltips (plugins)
```javascript
options: {
  plugins: {
    legend: {
      display: true, position: 'top',        // 'top'|'left'|'bottom'|'right'|'chartArea'
      labels: { usePointStyle: true, color: '#333', font: { size: 12 } },
      onClick: (e, item, legend) => { /* custom toggle */ }
    },
    title: { display: true, text: 'Quarterly Revenue', font: { size: 16 } },
    subtitle: { display: true, text: 'FY2024' },
    tooltip: {
      enabled: true, mode: 'index', intersect: false,
      callbacks: {
        label: (ctx) => `${ctx.dataset.label}: $${ctx.parsed.y.toLocaleString()}`,
        title: (items) => `Period ${items[0].label}`
      }
    }
  },
  interaction: { mode: 'nearest', intersect: false, axis: 'x' }
}
```
`mode: 'index'` + `intersect: false` gives the crosshair-style multi-series tooltip most dashboards want.

## How-To

### How to set colors / palette / theme
Chart.js has no palette system — you assign colors per dataset. Define an array and map it.
```javascript
const PALETTE = ['#4e79a7','#f28e2b','#e15759','#76b7b2','#59a14f','#edc948'];
const data = {
  labels: ['A','B','C','D'],
  datasets: [{
    label: 'Sales',
    data: [10, 20, 30, 40],
    backgroundColor: PALETTE,              // one color per bar/slice
    borderColor: PALETTE.map(c => c),
    borderWidth: 1
  }]
};
// Global theme defaults (apply to every chart on the page):
Chart.defaults.color = '#e5e7eb';          // text color (good for dark mode)
Chart.defaults.borderColor = 'rgba(255,255,255,0.1)';
Chart.defaults.font.family = "'Inter', system-ui, sans-serif";
```
For gradients, build a `CanvasGradient` from the chart context inside `backgroundColor`:
```javascript
backgroundColor: (ctx) => {
  const {chart} = ctx; const {ctx: c, chartArea} = chart;
  if (!chartArea) return;                  // first render has no area yet
  const g = c.createLinearGradient(0, chartArea.bottom, 0, chartArea.top);
  g.addColorStop(0, 'rgba(78,121,167,0.05)');
  g.addColorStop(1, 'rgba(78,121,167,0.6)');
  return g;
}
```

### How to make an area (filled line) chart
```javascript
new Chart(ctx, {
  type: 'line',
  data: { labels, datasets: [{ label:'Users', data, fill:'origin', tension:0.35,
    backgroundColor:'rgba(118,183,178,0.2)', borderColor:'#76b7b2' }] }
});
```
`fill` accepts `'origin'`, `'start'`, `'end'`, a dataset index, or `{target:'origin'}`. Requires the `Filler` plugin when tree-shaking.

### How to build a horizontal stacked bar
```javascript
new Chart(ctx, {
  type: 'bar',
  data: { labels, datasets: [
    { label:'Won',  data:won,  backgroundColor:'#59a14f' },
    { label:'Lost', data:lost, backgroundColor:'#e15759' } ] },
  options: { indexAxis: 'y', scales: { x: { stacked:true }, y: { stacked:true } } }
});
```

### How to add data labels on bars/slices
```javascript
// npm i chartjs-plugin-datalabels
import ChartDataLabels from 'chartjs-plugin-datalabels';
Chart.register(ChartDataLabels);
options: { plugins: { datalabels: { color:'#fff', formatter: v => `${v}%`, anchor:'end', align:'start' } } }
```

### How to export a chart to PNG
```javascript
const url = chart.toBase64Image('image/png', 1);   // dataURL
const a = document.createElement('a'); a.href = url; a.download = 'chart.png'; a.click();
```
For higher-res export set `devicePixelRatio: 2` in options before capture.

## Do's and Don'ts

### ✅ Do
- Wrap the canvas in a sized container and set `maintainAspectRatio:false` for responsive dashboards.
- Call `chart.destroy()` before re-creating a chart on the same canvas (React/Vue re-renders).
- Register only what you import in production builds; use `chart.js/auto` for prototypes.
- Mutate `chart.data` / `chart.options` then call `chart.update('none')` to skip animation on live data.

### ❌ Don't
- Don't create a new `Chart` on a canvas that already has one — you get "Canvas is already in use." Destroy first.
- Don't expect SVG output — Chart.js is canvas only; for print-quality vector use export at high DPR or switch to a Vega/Plotly.
- Don't push tens of thousands of points without `decimation` — canvas fill-rate collapses.
- Don't rely on a "theme" prop — there isn't one; theme via `Chart.defaults` and per-dataset colors.

## Styling, Theming & Customization
- Global defaults: `Chart.defaults.color`, `.backgroundColor`, `.borderColor`, `.font`, `.plugins.legend...`.
- Per-element: `pointRadius`, `pointStyle` ('circle','rect','triangle','star'), `borderDash:[5,5]`, `borderRadius` (bars).
- Dark mode: swap `Chart.defaults.color` and grid colors on a `prefers-color-scheme` media query, then `chart.update()`.
- Animations: `options.animation = { duration: 800, easing: 'easeOutQuart' }`; disable with `animation:false`.

## Advanced Features
- **Plugins**: implement lifecycle hooks (`beforeDraw`, `afterDraw`) to draw custom backgrounds, annotations, crosshairs. Popular: `chartjs-plugin-annotation`, `chartjs-plugin-zoom`, `chartjs-plugin-datalabels`.
- **Decimation**: `options.plugins.decimation = { enabled:true, algorithm:'lttb', samples:500 }` for large line series (requires indexed/parsed data and `parsing:false` for best effect).
- **Zoom/pan**: `chartjs-plugin-zoom` adds wheel/drag zoom and pan.
- **Live updates**: streaming via `chartjs-plugin-streaming` for realtime axes.

## Common Pitfalls & Troubleshooting
- Blank chart + console error about unregistered scale → register the scale/controller (tree-shaking).
- Time axis error → install and import a date adapter.
- Chart overflows container → set explicit container height and `maintainAspectRatio:false`.
- Fuzzy chart on retina → Chart.js auto-handles DPR; if you set canvas width/height in HTML attributes it fights the responsive sizing. Size via CSS/container instead.
- Large data lag → enable decimation, set `pointRadius:0`, `animation:false`, `parsing:false` with pre-formatted `{x,y}`.

## Best For / Avoid For
`dashboards`, `responsive-charts`, `product-analytics`, `quick-prototypes`, `mobile-web`, `mixed-bar-line` — choose Chart.js.
Avoid for: `3D`, `100k+ points`, `vector/print output`, `network graphs`, `deep bespoke interactions` — reach for Plotly, ECharts, D3, or Vega instead.

## See Also
- `plotly_js.md` — richer types, WebGL, 3D, built-in export
- `highcharts.md` — commercial, stock charts, boost module for big data
- `vega-lite.md` / `observable-plot.md` — declarative grammar-of-graphics
- `d3_js.md` — when you need full control
- `../use-case/data-visualization.md`
