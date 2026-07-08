# Google Charts — Free interactive charts loaded from Google's CDN

Google Charts is a free JavaScript charting library loaded via `loader.js`. You build a `DataTable`, pick a chart class, set an `options` object, and call `chart.draw(data, options)`. It renders SVG (most charts) or HTML, is interactive by default (tooltips, selection, animation), and integrates directly with Google Sheets. No npm package — it is CDN-loaded and always current.

**Current Version**: `'current'` frozen channel (evergreen)  **License**: Free to use (Google Charts ToS); not open source, must load from Google's servers  **Runtime**: browser, SVG/HTML

## Official Resources & Documentation
- Docs: https://developers.google.com/chart
- Gallery: https://developers.google.com/chart/interactive/docs/gallery
- Loader/ToS: https://developers.google.com/chart/interactive/docs/basic_load_libs
- Reference (each chart's options): linked from each gallery page

## Installation & Setup
No package install — load the loader, request packages, then draw on a callback:
```html
<script src="https://www.gstatic.com/charts/loader.js"></script>
<div id="chart" style="width:600px; height:400px"></div>
<script>
  google.charts.load('current', { packages: ['corechart'] });
  google.charts.setOnLoadCallback(drawChart);
  function drawChart() { /* build DataTable + draw */ }
</script>
```
Packages: `corechart` (line/bar/column/area/pie/scatter/combo/bubble/histogram), `bar` (Material bars), `line` (Material line), `table`, `gauge`, `geochart`, `map`, `timeline`, `gantt`, `treemap`, `sankey`, `wordtree`, `calendar`, `annotationchart`, `orgchart`, `controls` (dashboards).

## Core API Reference

### Building data — three ways
```javascript
// 1) arrayToDataTable (quickest)
const data = google.visualization.arrayToDataTable([
  ['Month', 'Sales', 'Expenses'],
  ['Jan', 1000, 400],
  ['Feb', 1170, 460],
  ['Mar', 660,  1120]
]);

// 2) DataTable API (typed columns, roles)
const dt = new google.visualization.DataTable();
dt.addColumn('string', 'Month');
dt.addColumn('number', 'Sales');
dt.addColumn({type:'string', role:'tooltip'});   // custom tooltip column
dt.addRows([['Jan', 1000, '1k sales'], ['Feb', 1170, '1.17k']]);

// 3) From Google Sheets query
const query = new google.visualization.Query('https://docs.google.com/spreadsheets/d/KEY/gviz/tq');
query.send(response => chart.draw(response.getDataTable(), options));
```

### Drawing
```javascript
const chart = new google.visualization.LineChart(document.getElementById('chart'));
chart.draw(data, options);
google.visualization.events.addListener(chart, 'select', () => {
  const sel = chart.getSelection();   // interaction
});
```

## Chart Types
- **Core (SVG)**: `LineChart`, `ColumnChart` (vertical bars), `BarChart` (horizontal), `AreaChart`, `PieChart`, `ScatterChart`, `BubbleChart`, `ComboChart`, `Histogram`, `CandlestickChart`, `SteppedAreaChart`.
- **Material** (newer look): `google.charts.Bar`, `google.charts.Line`, `google.charts.Scatter` — use `google.charts.Bar.convertOptions(options)`.
- **Specialized**: `GeoChart`, `Map` (Google Maps), `Gauge`, `Timeline`, `Gantt`, `TreeMap`, `Sankey`, `WordTree`, `Calendar`, `OrgChart`, `Table`, `AnnotationChart` (financial), `PieChart` with `pieHole` (donut).

## Options — the customization surface
```javascript
const options = {
  title: 'Company Performance',
  titleTextStyle: { fontSize: 16, color: '#333' },
  width: 600, height: 400,
  backgroundColor: 'transparent',
  chartArea: { left: 60, top: 40, width: '80%', height: '70%' },
  hAxis: { title: 'Month', slantedText: true, gridlines: { color: '#eee' } },
  vAxis: { title: 'USD', format: 'short', minValue: 0, viewWindow: { min: 0 } },
  legend: { position: 'bottom', alignment: 'center', textStyle: { color: '#555' } },
  colors: ['#4e79a7', '#f28e2b', '#e15759'],
  tooltip: { isHtml: true, trigger: 'focus' },
  animation: { startup: true, duration: 800, easing: 'out' },
  pointSize: 5, lineWidth: 2, curveType: 'function',   // smooth lines
  isStacked: true                                        // or 'percent','relative'
};
```

## How-To

### How to set colors / palette / theme
```javascript
// 1) Series palette (applied in order)
const options = { colors: ['#4e79a7','#f28e2b','#e15759','#76b7b2','#59a14f'] };

// 2) Per-series color + style
const options2 = { series: {
  0: { color: '#4e79a7', lineWidth: 3 },
  1: { color: '#e15759', lineDashStyle: [4,4], type: 'line' }  // combo per-series type
}};

// 3) Color a column by value (style role column)
dt.addColumn({type:'string', role:'style'});
dt.addRows([['A', 10, 'color:#59a14f'], ['B', -4, 'color:#e15759']]);

// 4) Dark theme
const dark = { backgroundColor:'#111', titleTextStyle:{color:'#eee'},
  hAxis:{textStyle:{color:'#ccc'}, gridlines:{color:'#333'}},
  vAxis:{textStyle:{color:'#ccc'}, gridlines:{color:'#333'}},
  legend:{textStyle:{color:'#ccc'}} };
```

### How to make a donut chart
```javascript
const options = { title: 'Traffic', pieHole: 0.4,
  slices: { 0: {color:'#4e79a7'}, 1: {color:'#f28e2b'} } };
new google.visualization.PieChart(el).draw(data, options);
```

### How to build a combo (bar + line) chart
```javascript
const options = { seriesType: 'bars',
  series: { 2: { type: 'line' } },   // 3rd column becomes a line
  title: 'Revenue vs Target' };
new google.visualization.ComboChart(el).draw(data, options);
```

### How to make it responsive
```javascript
function draw() { chart.draw(data, { ...options, width: el.clientWidth }); }
window.addEventListener('resize', () => { clearTimeout(t); t = setTimeout(draw, 200); });
```
Or set `width`/`height` to omit and give the container a fixed size; Google Charts fills it.

### How to export a chart image
```javascript
google.visualization.events.addListener(chart, 'ready', () => {
  const uri = chart.getImageURI();   // PNG data URI (SVG charts)
  document.getElementById('png').src = uri;
});
```

## Do's and Don'ts

### ✅ Do
- Always draw inside `setOnLoadCallback` (or the promise) — the library isn't ready before load.
- Use `DataTable` with typed columns and `role` columns (tooltip, style, annotation) for control.
- Format numbers/dates with `NumberFormat`/`DateFormat` formatters on the DataTable.
- Use `ChartWrapper` + `Dashboard` + `controls` package for linked filter dashboards.

### ❌ Don't
- Don't self-host `loader.js` — the ToS requires loading from `gstatic.com`; there is no offline/npm build.
- Don't expect Material charts to support every classic option — many `hAxis`/`vAxis` options differ; run `Bar.convertOptions`.
- Don't draw before the container has size — 0×0 containers render blank.
- Don't send sensitive data through the Sheets `gviz` query endpoint on public URLs.

## Styling, Theming & Customization
- `colors` (series palette), `series.<i>` (per-series color/type/axis), `slices.<i>` (pie).
- `role:'style'` columns override per-datum color/stroke/opacity (`'color:#f00; stroke-width:2'`).
- Text styling: `titleTextStyle`, `hAxis.textStyle`, `legend.textStyle`, `annotations.textStyle`.
- `chartArea` controls plot padding; `backgroundColor` (string or `{fill, stroke, strokeWidth}`).
- Animation: `animation:{startup:true, duration, easing:'linear'|'in'|'out'|'inAndOut'}`.

## Advanced Features
- **Dashboards**: `google.visualization.Dashboard` + `ControlWrapper` (CategoryFilter, NumberRangeFilter, ChartRangeFilter) bind controls to charts.
- **GeoChart / Map**: region/marker maps; `GeoChart` is SVG world/region maps, `Map` uses Google Maps (needs `mapsApiKey`).
- **Formatters**: `NumberFormat`, `DateFormat`, `ColorFormat`, `ArrowFormat`, `BarFormat` transform cell display.
- **Events**: `select`, `onmouseover`, `ready`, `error`, `rangechange`.
- **DataView**: derive filtered/computed views without copying the DataTable (`setColumns`, `setRows`).

## Integration Notes
- **Promise API**: `google.charts.load('current', {packages:['corechart']}).then(drawChart)` instead of `setOnLoadCallback`.
- **React**: use `react-google-charts` (`<Chart chartType="PieChart" data={} options={} />`) which handles loading/redraw.
- **Google Sheets**: point a `Query` at a sheet's `gviz/tq` endpoint (sheet must be link-shared) for live data.
- **No bundler control**: the library is always the CDN evergreen build; you cannot pin a version or self-host.

### How to build a linked filter dashboard
```javascript
const dashboard = new google.visualization.Dashboard(document.getElementById('dash'));
const slider = new google.visualization.ControlWrapper({
  controlType: 'NumberRangeFilter', containerId: 'filter',
  options: { filterColumnLabel: 'Sales' } });
const chart = new google.visualization.ChartWrapper({
  chartType: 'ColumnChart', containerId: 'chart',
  options: { legend: 'none' } });
dashboard.bind(slider, chart);
dashboard.draw(data);
```

## Common Pitfalls & Troubleshooting
- Blank chart → drawing before load callback, or container has no dimensions.
- Wrong package → e.g. GeoChart needs `packages:['geochart']`; loading only `corechart` fails silently.
- Material vs classic option mismatch → many options renamed; consult the Material page and `convertOptions`.
- Tooltips not HTML → set `tooltip:{isHtml:true}` and add an HTML tooltip role column.
- Requires network → no offline mode; charts won't render without access to gstatic.

## Best For / Avoid For
`google-sheets-integration`, `free-dashboards`, `geo-charts`, `timelines-gantt`, `quick-embeds`, `org-charts` — choose Google Charts.
Avoid for: `offline/air-gapped apps`, `npm-bundled builds`, `deep-custom-visuals` (D3/Vega), `huge-datasets`, `open-source-requirement`.

## See Also
- `chart_js.md` — open-source canvas alternative
- `highcharts.md` — commercial, richer feature set
- `plotly_js.md` — scientific/3D/interactive
- `../use-case/data-visualization.md`
