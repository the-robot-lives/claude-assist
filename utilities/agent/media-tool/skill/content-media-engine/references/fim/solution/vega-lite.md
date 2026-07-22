# Vega-Lite — Concise grammar of interactive graphics (JSON)

Vega-Lite is a high-level declarative grammar where a chart is described by a `mark` (the geometry) plus `encoding` (the mapping of data fields to visual channels). It auto-generates scales, axes, and legends, supports statistical transforms and interaction, and compiles down to full Vega. A useful bar chart is often 6 lines of JSON.

**Current Version**: Vega-Lite 5.x (current major)  **License**: BSD-3-Clause  **Runtime**: browser via `vega-embed`, or Node/Python (Altair) / R

## Official Resources & Documentation
- Docs: https://vega.github.io/vega-lite/docs/
- Examples: https://vega.github.io/vega-lite/examples/
- Online editor: https://vega.github.io/editor/
- GitHub: https://github.com/vega/vega-lite

## Installation & Setup
```bash
npm install vega vega-lite vega-embed
```
```html
<script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
```
```javascript
vegaEmbed('#vis', spec, { actions: true }).then(({view}) => { /* view API */ });
```

## Core Grammar — top-level spec
```json
{
  "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
  "data":   { "url": "data/cars.json" },
  "mark":   "point",
  "encoding": {
    "x": {"field": "Horsepower",   "type": "quantitative"},
    "y": {"field": "Miles_per_Gallon", "type": "quantitative"},
    "color": {"field": "Origin",   "type": "nominal"}
  },
  "width": 400, "height": 300, "title": "MPG vs Horsepower"
}
```

## Marks
String or object form:
`bar`, `line`, `area`, `point`, `circle`, `square`, `tick`, `rect`, `rule`, `text`, `arc` (pie/donut), `trail`, `geoshape`, `image`, `errorbar`, `errorband`, `boxplot`, `density` (via transform).
```json
"mark": {"type": "line", "point": true, "interpolate": "monotone", "strokeWidth": 2}
```
`interpolate`: `linear`, `monotone`, `basis`, `step`, `step-after`, `cardinal`. Pie: `{"type":"arc","innerRadius":50}`.

## Encoding Channels
- **Position**: `x`, `y`, `x2`, `y2`, `xError`, `theta`, `theta2` (arc), `radius`, `longitude`, `latitude`.
- **Mark properties**: `color`, `fill`, `stroke`, `opacity`, `fillOpacity`, `strokeOpacity`, `strokeWidth`, `strokeDash`, `size`, `shape`, `angle`.
- **Text/tooltip**: `text`, `tooltip` (array or `true`), `href`, `key`, `description`.
- **Detail/order**: `detail` (group without visual channel), `order` (stacking/line order).
- **Facet**: `facet`, `row`, `column` (small multiples).

### Field types (the `type`)
- `quantitative` (Q) — continuous numeric → linear scale
- `nominal` (N) — unordered category → discrete color/scale
- `ordinal` (O) — ordered category → ordered scale
- `temporal` (T) — dates/times → time scale
- `geojson` — geographic shapes
Shorthand: `{"field":"date","type":"temporal"}` or string `"date:T"` in some hosts.

### Channel options
```json
"y": {
  "field": "sales", "type": "quantitative",
  "aggregate": "sum",                      // count/sum/mean/median/min/max/stdev...
  "scale": {"type": "log", "zero": false, "domain": [1,1000]},
  "axis": {"title": "Sales", "format": "$,.0f", "grid": true, "labelAngle": 0},
  "sort": "-x", "stack": "normalize",      // stack: true|"zero"|"normalize"|"center"|null
  "bin": {"maxbins": 30},
  "timeUnit": "yearmonth"
}
```

## Transforms (data-level)
```json
"transform": [
  {"filter": "datum.year > 2000"},
  {"calculate": "datum.profit / datum.revenue", "as": "margin"},
  {"aggregate": [{"op":"mean","field":"price","as":"avg"}], "groupby":["cat"]},
  {"bin": true, "field": "x", "as": "xbin"},
  {"window": [{"op":"rank","as":"r"}], "sort":[{"field":"v","order":"descending"}]},
  {"fold": ["a","b","c"], "as": ["key","value"]},
  {"regression": "y", "on": "x"},
  {"density": "value", "bandwidth": 0.3},
  {"loess": "y", "on": "x"},
  {"lookup": "id", "from": {"data": {"url":"lookup.json"}, "key":"id", "fields":["name"]}}
]
```

## Composition — layer, facet, concat, repeat
```json
// Layer (overlay marks sharing axes)
{ "layer": [
    {"mark":"bar", "encoding":{...}},
    {"mark":{"type":"rule","color":"red"}, "encoding":{"y":{"aggregate":"mean","field":"v"}}}
]}

// Facet (small multiples)
{ "facet": {"column": {"field":"region","type":"nominal"}},
  "spec": {"mark":"line","encoding":{...}} }

// Concatenation
{ "hconcat": [specA, specB] }      // also vconcat, concat (wrap)

// Repeat (same chart over several fields)
{ "repeat": ["A","B","C"], "spec": {"mark":"bar",
   "encoding":{"x":{"field":{"repeat":"repeat"},"type":"quantitative"}}} }
```
`resolve` controls whether layered/faceted views share or independently scale axes/legends: `{"resolve":{"scale":{"y":"independent"}}}`.

## Projections (geo)
```json
{ "projection": {"type": "albersUsa"},
  "layer": [
    {"data":{"url":"us-10m.json","format":{"type":"topojson","feature":"states"}},
     "mark":{"type":"geoshape","fill":"#eee","stroke":"white"}},
    {"data":{"url":"cities.json"},"mark":"circle",
     "encoding":{"longitude":{"field":"lon"},"latitude":{"field":"lat"}}}
]}
```
Projection types match Vega: `albersUsa`, `mercator`, `equalEarth`, `orthographic`, `naturalEarth1`, etc.

## Interactivity (selections / params)
```json
"params": [
  {"name":"brush","select":{"type":"interval","encodings":["x"]}},
  {"name":"hover","select":{"type":"point","on":"mouseover"}}
],
"mark":"point",
"encoding":{
  "color":{"condition":{"param":"brush","field":"Origin","type":"nominal"},"value":"lightgray"}
}
```
Selection types: `interval` (drag brush) and `point` (click/hover). Bind to inputs: `{"bind":{"input":"range","min":0,"max":100}}` for sliders/dropdowns.

## How-To

### How to set colors / palette / theme
```json
// 1) Categorical scheme
"color": {"field":"cat","type":"nominal","scale":{"scheme":"tableau10"}}
// 2) Sequential (continuous)
"color": {"field":"v","type":"quantitative","scale":{"scheme":"viridis"}}
// 3) Explicit domain→range map
"color": {"field":"cat","type":"nominal",
  "scale":{"domain":["A","B"],"range":["#4e79a7","#e15759"]}}
// 4) Fixed constant color (no legend)
"mark": {"type":"bar","color":"#4e79a7"}
```
Reverse a scheme: `"scale":{"scheme":"viridis","reverse":true}`. Diverging: `redblue`, `spectral`, `blueorange`. Global theme: pass `{theme:'dark'}` (or `quartz`, `ggplot2`, `fivethirtyeight`, `latimes`, `vox`) to `vegaEmbed`, or set a `"config"` block: `"config":{"background":"#111","axis":{"gridColor":"#333","labelColor":"#ccc"},"range":{"category":["#4e79a7","#f28e2b"]}}`.

### How to make a stacked / normalized bar
```json
{"mark":"bar","encoding":{
  "x":{"field":"month","type":"ordinal"},
  "y":{"aggregate":"sum","field":"sales","type":"quantitative","stack":"normalize"},
  "color":{"field":"product","type":"nominal"}}}
```

### How to add a regression / trend line
```json
{"layer":[
  {"mark":"point","encoding":{"x":{"field":"x","type":"quantitative"},"y":{"field":"y","type":"quantitative"}}},
  {"transform":[{"regression":"y","on":"x"}],
   "mark":{"type":"line","color":"red"},
   "encoding":{"x":{"field":"x","type":"quantitative"},"y":{"field":"y","type":"quantitative"}}}
]}
```

### How to export / embed with a toolbar
```javascript
vegaEmbed('#vis', spec, {actions: {export:true, source:false, editor:true}});
// programmatic image:
const {view} = await vegaEmbed('#vis', spec);
const url = await view.toImageURL('png', 2);   // scale 2x
```

## Do's and Don'ts

### ✅ Do
- Always set the field `type` — it determines scale/axis/legend behavior.
- Use `aggregate`/`bin`/`timeUnit` in the encoding instead of pre-aggregating when possible.
- Reach for `layer`/`facet`/`concat`/`repeat` before writing raw Vega.
- Prototype in the Vega editor; it shows the compiled Vega and errors.

### ❌ Don't
- Don't push >50k points at an SVG renderer — sample/aggregate or use raw Vega + Canvas.
- Don't mix incompatible field types (temporal field typed as nominal loses ordering).
- Don't expect arbitrary custom interactions — eject to Vega for those.
- Don't forget `stack:null` when you want overlapping (not stacked) areas.

## Styling, Theming & Customization
- **config**: top-level `"config"` sets defaults for `axis`, `legend`, `mark`, `title`, `range`, `view`, `background`.
- **Themes** via `vega-embed`'s `theme` option or the `vega-themes` package.
- Per-encoding `axis`/`legend`/`scale` objects override defaults.
- Fonts: `"config":{"axis":{"labelFont":"Inter"},"title":{"font":"Inter"}}`.

## Advanced Features
- **Datasets & params**: named `datasets`, bound input widgets (sliders/dropdowns/radios).
- **Cross-filtering dashboards**: `interval` selection in one view filtering another via `condition`.
- **Statistical**: `regression`, `loess`, `density`, `quantile`, `boxplot`, `errorband` marks.
- **Compile in code**: `vegaLite.compile(spec).spec` yields Vega for server rendering.
- **Altair** (Python) and the R/Julia bindings emit Vega-Lite JSON — the same spec surface.

## Common Pitfalls & Troubleshooting
- Legend/axis missing → you set a constant `value` instead of a `field` encoding.
- Dates plotted as strings/categories → set `type:"temporal"`.
- Bars not stacking → check the color/detail channel and `stack` setting.
- Independent scales needed across facets → add `resolve.scale.y:"independent"`.
- Big data lag → aggregate, `sample`, or switch to Vega with Canvas.

## Best For / Avoid For
`statistical-charts`, `dashboards`, `exploratory-data-analysis`, `academic-figures`, `linked-brushing`, `small-multiples` — choose Vega-Lite.
Avoid for: `>50k-points`, `3D`, `pixel-perfect-bespoke-interaction` (Vega/D3), `heavy-animation`.

## See Also
- `vega.md` — the full grammar Vega-Lite compiles to
- `observable-plot.md` — JS grammar-of-graphics with a terser API
- `altair.md` — Python bindings emitting Vega-Lite
- `plotly_js.md` — trace-based alternative
- `../use-case/data-visualization.md`
