# Plotly.js — High-level scientific & 3D charting for the web

Plotly.js is a declarative charting library built on D3 and WebGL. A chart is a `(data, layout, config)` triple where `data` is an array of *traces*. It ships 40+ trace types (2D, statistical, 3D, maps, financial), interactive pan/zoom/hover out of the box, and a built-in toolbar with PNG/SVG export. It underpins Plotly's Python/R/Julia bindings and Dash.

**Current Version**: 2.35.x (current major)  **License**: MIT (open source)  **Bundle**: ~3.5MB full; use partial bundles (`plotly.js-basic-dist`, `-cartesian`, `-gl3d`) to shrink

## Official Resources & Documentation
- JS docs: https://plotly.com/javascript/
- Figure reference (every attribute): https://plotly.com/javascript/reference/
- GitHub: https://github.com/plotly/plotly.js
- npm: https://www.npmjs.com/package/plotly.js-dist-min
- Partial bundles: https://github.com/plotly/plotly.js/blob/master/dist/README.md

## Installation & Setup

### Package manager
```bash
npm install plotly.js-dist-min          # v2.35.x, prebuilt
# or smaller partial bundles:
npm install plotly.js-basic-dist-min    # scatter/bar/pie only
```

### CDN
```html
<script src="https://cdn.plot.ly/plotly-2.35.2.min.js" charset="utf-8"></script>
```

### ESM
```javascript
import Plotly from 'plotly.js-dist-min';
```

## Core API Reference
```javascript
Plotly.newPlot(divOrId, data, layout, config);   // create/replace
Plotly.react(div, data, layout, config);          // efficient update (diff-based)
Plotly.restyle(div, {'marker.color':'red'}, [0]); // update trace attrs
Plotly.relayout(div, {'xaxis.range':[0,10]});      // update layout attrs
Plotly.addTraces(div, newTrace);
Plotly.deleteTraces(div, [1]);
Plotly.downloadImage(div, {format:'png', width:1200, height:800, filename:'chart'});
Plotly.toImage(div, {format:'svg'}).then(url => ...);
Plotly.purge(div);                                 // free memory (SPA cleanup)
```

### Trace structure
```javascript
const trace = {
  type: 'scatter', mode: 'lines+markers',
  x: [1,2,3,4], y: [10,15,13,17],
  name: 'Series A',
  marker: { color: '#4e79a7', size: 8 },
  line: { color: '#4e79a7', width: 2, dash: 'solid' },
  hovertemplate: '%{x}: %{y}<extra>Series A</extra>'
};
Plotly.newPlot('div', [trace], { title: 'Demo' });
```

## Trace / Chart Types
- **Cartesian 2D**: `scatter` (line/markers/area via `fill`), `bar`, `histogram`, `box`, `violin`, `heatmap`, `contour`, `histogram2d`, `histogram2dcontour`, `scattergl` (WebGL, for large data).
- **Statistical**: `box`, `violin`, `histogram`, `histogram2dcontour`, `splom` (scatter matrix).
- **Financial**: `candlestick`, `ohlc`, `waterfall`, `funnel`, `funnelarea`.
- **Part-to-whole**: `pie`, `sunburst`, `treemap`, `icicle`, `sankey`, `parcats` (parallel categories), `parcoords` (parallel coordinates).
- **3D**: `scatter3d`, `surface`, `mesh3d`, `cone`, `streamtube`, `isosurface`, `volume`.
- **Maps**: `scattergeo`, `choropleth`, `scattermapbox`/`choroplethmapbox` (Mapbox/MapLibre tiles), `densitymapbox`.
- **Indicators**: `indicator` (KPI number, gauge, delta), `table`.

```javascript
// 3D surface
Plotly.newPlot('d', [{ z: zMatrix, type: 'surface', colorscale: 'Viridis' }],
  { scene: { xaxis:{title:'X'}, yaxis:{title:'Y'}, zaxis:{title:'Z'} } });
```

## Scales & Axes
```javascript
layout: {
  xaxis: {
    title: { text: 'Date' }, type: 'date',          // '-'|'linear'|'log'|'date'|'category'|'multicategory'
    range: ['2024-01-01','2024-12-31'], rangeslider: {}, rangeselector: {},
    gridcolor: 'rgba(0,0,0,0.08)', zeroline: false, tickformat: '%b %Y'
  },
  yaxis: { title:{text:'Value'}, type:'log', tickformat:'.2s', autorange: true },
  yaxis2: { overlaying:'y', side:'right', title:{text:'Secondary'} }  // dual axis
}
```
Assign a trace to a secondary axis with `yaxis: 'y2'`.

## Legends, Tooltips, Interactivity
```javascript
layout: {
  legend: { orientation:'h', x:0, y:1.1, bgcolor:'rgba(0,0,0,0)',
            font:{color:'#333'}, itemclick:'toggle', itemdoubleclick:'toggleothers' },
  hovermode: 'x unified'   // 'closest'|'x'|'y'|'x unified'|'y unified'|false
}
// Per-trace tooltip content:
trace.hovertemplate = '<b>%{x}</b><br>%{y:$,.0f}<extra>%{fullData.name}</extra>';
```
`<extra></extra>` hides the trace-name box. `hovermode:'x unified'` = combined multi-series tooltip.

## How-To

### How to set colors / palette / theme
Per-trace color, categorical color arrays, continuous colorscales, and full templates:
```javascript
// 1) Single trace color
{ type:'bar', x, y, marker:{ color:'#4e79a7' } }

// 2) Color each point by a data column (categorical/continuous)
{ type:'scatter', mode:'markers', x, y,
  marker:{ color: values, colorscale:'Viridis', showscale:true,
           colorbar:{title:'Metric'} } }

// 3) Discrete palette across traces
const PALETTE = ['#4e79a7','#f28e2b','#e15759','#76b7b2','#59a14f'];
traces.forEach((t,i) => t.marker = { color: PALETTE[i % PALETTE.length] });

// 4) Reusable theme via template + layout.colorway
const layout = {
  colorway: PALETTE,                     // default trace color cycle
  template: {
    layout: {
      paper_bgcolor:'#111', plot_bgcolor:'#111',
      font:{ color:'#e5e7eb', family:'Inter, sans-serif' },
      xaxis:{ gridcolor:'rgba(255,255,255,0.1)' },
      yaxis:{ gridcolor:'rgba(255,255,255,0.1)' }
    }
  }
};
```
Built-in colorscales: `Viridis`, `Cividis`, `Blues`, `RdBu`, `Portland`, `Jet`, `Hot`, `Electric`, `Picnic`, `Turbo`. Reverse with `reversescale:true`. Custom: `colorscale:[[0,'#fff'],[1,'#00f']]`.

### How to make a dual-axis bar + line combo
```javascript
Plotly.newPlot('d', [
  { type:'bar', x, y:volume, name:'Volume', marker:{color:'#c9d6e5'} },
  { type:'scatter', x, y:price, name:'Price', yaxis:'y2', line:{color:'#e15759'} }
], { yaxis:{title:'Volume'}, yaxis2:{title:'Price', overlaying:'y', side:'right'} });
```

### How to draw a heatmap / contour
```javascript
Plotly.newPlot('d', [{ z: matrix, x: cols, y: rows, type:'heatmap',
  colorscale:'RdBu', reversescale:true, colorbar:{title:'corr'} }]);
```

### How to export to PNG/SVG at high resolution
```javascript
Plotly.downloadImage('d', { format:'png', width:1600, height:1000, scale:2, filename:'export' });
// or get a dataURL:
Plotly.toImage('d', { format:'svg' }).then(dataUrl => { /* embed/save */ });
```

### How to handle large datasets (WebGL)
```javascript
// scattergl renders 100k–1M points; scatter (SVG) chokes past ~10k
{ type:'scattergl', mode:'markers', x, y, marker:{size:3, opacity:0.5} }
```

## Do's and Don'ts

### ✅ Do
- Use `Plotly.react(div, data, layout)` for updates — it diffs and is far faster than `newPlot`.
- Switch line/scatter to `scattergl` and heatmaps stay canvas for big data.
- Set `config: { responsive: true }` and let the div size the chart.
- Use `hovertemplate` for precise tooltip control instead of fighting default hoverinfo.

### ❌ Don't
- Don't ship the full 3.5MB bundle if you only draw bars/lines — use a partial dist.
- Don't call `newPlot` on every state change in React — memory grows; use `react` and `purge` on unmount.
- Don't use SVG `scatter` for 50k+ points — it will freeze the tab.
- Don't forget `<extra></extra>` in hovertemplate or you get a duplicate trace-name box.

## Styling, Theming & Customization
- `layout.template` is the theme system — register with `Plotly.setPlotConfig` or pass per-call. Community themes exist (e.g., dark).
- `config` options: `displayModeBar`, `modeBarButtonsToRemove`, `staticPlot` (kill interactivity), `scrollZoom`, `toImageButtonOptions`.
- Fonts: `layout.font`, per-axis `title.font`, `tickfont`.
- Annotations & shapes: `layout.annotations` (text callouts), `layout.shapes` (lines, rects, circles) for thresholds/regions.

## Advanced Features
- **Animations**: `Plotly.animate(div, {data, traces, layout}, {transition:{duration:500}})` and `frames` for transitions.
- **Subplots**: grid via `xaxis`/`xaxis2`/`yaxis2` + `layout.grid:{rows,columns,pattern:'independent'}`.
- **3D & scientific**: surfaces, isosurfaces, streamtubes with lighting controls.
- **Events**: `div.on('plotly_click', d => ...)`, `plotly_hover`, `plotly_selected` (box/lasso), `plotly_relayout`.
- **Maps**: Mapbox/MapLibre-backed traces; free with MapLibre style (no token) or Mapbox token for premium tiles.

## Integration Notes
- **React**: use `react-plotly.js` (`<Plot data={} layout={} config={}/>`), which wraps `Plotly.react` for efficient updates; or call `Plotly.react` in a `useEffect` and `Plotly.purge` on unmount.
- **Angular/Vue**: `angular-plotly.js` / `vue3-plotly` wrappers exist; otherwise call the imperative API on a `ViewChild`/`ref`.
- **Dash** (Python) renders these figures server-driven; the JSON figure spec is identical across languages.
- **Bundle size**: import a partial dist (`plotly.js-basic-dist-min`) or a custom bundle to avoid shipping 3.5MB.

### How to add threshold lines / shaded regions
```javascript
layout: {
  shapes: [
    { type:'line', x0:0, x1:1, xref:'paper', y0:80, y1:80, line:{color:'red', dash:'dash'} },
    { type:'rect', x0:'2024-06-01', x1:'2024-07-01', y0:0, y1:1, yref:'paper',
      fillcolor:'gray', opacity:0.15, line:{width:0} }
  ],
  annotations: [ { x:'2024-06-15', y:1, yref:'paper', text:'Launch', showarrow:false } ]
}
```

## Common Pitfalls & Troubleshooting
- Chart not responsive → set `{responsive:true}` in config and give the div a width; call `Plotly.Plots.resize(div)` on container resize.
- 3D not rendering → WebGL disabled/unavailable; check `gl3d` bundle is included.
- Memory climbs in SPA → call `Plotly.purge(div)` on teardown.
- Tooltip shows raw numbers → add `hovertemplate` with `d3-format` specifiers (`%{y:$,.2f}`).
- Category axis reorders alphabetically → set `xaxis.categoryorder:'array'` + `categoryarray:[...]`.

## Best For / Avoid For
`scientific-plots`, `3d-surfaces`, `statistical-charts`, `financial-candlestick`, `heatmaps`, `maps`, `dashboards-with-export`, `dash-apps` — choose Plotly.
Avoid for: `tiny-bundle-requirements`, `fully-bespoke-visual-design` (D3), `simple-mobile-widgets` (Chart.js).

## See Also
- `plotly-python.md` — same figure model from Python
- `chart_js.md` — lighter canvas alternative
- `highcharts.md` — commercial equivalent with stock module
- `vega.md` / `vega-lite.md` — declarative JSON grammar
- `../use-case/data-visualization.md`
