# Vega — Full declarative visualization grammar (JSON)

Vega is a low-level visualization *grammar*: a single JSON object fully specifies data, transforms, scales, axes, legends, marks, and interactive signals. The Vega runtime parses the spec and renders to Canvas or SVG. It is the compilation target of Vega-Lite and the engine behind reproducible, shareable, server-renderable graphics. Choose raw Vega when you need custom interaction/layout that Vega-Lite can't express.

**Current Version**: Vega 5.30.x (current major)  **License**: BSD-3-Clause  **Runtime**: browser (Canvas/SVG) or Node (`vega` + `canvas`)

## Official Resources & Documentation
- Docs: https://vega.github.io/vega/docs/
- Examples: https://vega.github.io/vega/examples/
- Online editor: https://vega.github.io/editor/
- GitHub: https://github.com/vega/vega
- Vega-Lite (higher level): https://vega.github.io/vega-lite/

## Installation & Setup
```bash
npm install vega            # v5.30.x
npm install vega canvas     # Node.js server-side rendering
```
```html
<script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
```
```javascript
import * as vega from 'vega';
const view = new vega.View(vega.parse(spec), { renderer: 'svg' })
  .initialize('#vis').run();
```

## Core Grammar — the top-level spec blocks
A Vega spec is an object with these keys (all optional except the ones your marks reference):
```json
{
  "$schema": "https://vega.github.io/schema/vega/v5.json",
  "width": 400, "height": 200, "padding": 5,
  "background": "white",
  "signals":  [ ... ],
  "data":     [ ... ],
  "scales":   [ ... ],
  "projections": [ ... ],
  "axes":     [ ... ],
  "legends":  [ ... ],
  "marks":    [ ... ]
}
```

### data + transforms
```json
"data": [
  { "name": "source", "url": "data/movies.json", "format": {"type":"json"} },
  { "name": "binned", "source": "source",
    "transform": [
      { "type": "filter", "expr": "datum.IMDB_Rating != null" },
      { "type": "bin", "field": "IMDB_Rating", "extent": [0,10], "as": ["bin0","bin1"] },
      { "type": "aggregate", "groupby": ["bin0","bin1"], "ops": ["count"], "as": ["count"] }
    ] }
]
```
Transform types: `aggregate`, `bin`, `collect` (sort), `filter`, `flatten`, `fold`, `formula`, `impute`, `joinaggregate`, `lookup`, `pivot`, `project`, `sample`, `sequence`, `stack`, `window`, plus layout transforms `force` (force-directed), `stratify`+`tree`/`treemap`/`pack`/`partition` (hierarchies), `geopath`/`geoshape`/`geopoint` (geo), `contour`, `voronoi`, `wordcloud`, `linkpath`.

### scales
```json
"scales": [
  { "name": "x", "type": "band", "domain": {"data":"table","field":"category"},
    "range": "width", "padding": 0.1 },
  { "name": "y", "type": "linear", "domain": {"data":"table","field":"amount"},
    "range": "height", "nice": true, "zero": true },
  { "name": "color", "type": "ordinal", "domain": {"data":"table","field":"category"},
    "range": {"scheme": "category20"} }
]
```
Scale types: `linear`, `log`, `pow`, `sqrt`, `symlog`, `time`, `utc`, `ordinal`, `band`, `point`, `quantile`, `quantize`, `threshold`, `bin-ordinal`. Ranges: `"width"`, `"height"`, `{"scheme":"viridis"}`, explicit arrays, `{"step":20}`.

### marks
```json
"marks": [
  { "type": "rect", "from": {"data": "table"},
    "encode": {
      "enter": {
        "x":  {"scale":"x","field":"category"},
        "width": {"scale":"x","band":1},
        "y":  {"scale":"y","field":"amount"},
        "y2": {"scale":"y","value":0},
        "fill": {"scale":"color","field":"category"}
      },
      "update": {"fillOpacity": {"value": 1}},
      "hover":  {"fillOpacity": {"value": 0.6}}
    } }
]
```
Mark types: `arc`, `area`, `image`, `group`, `line`, `path`, `rect`, `rule`, `shape`, `symbol`, `text`, `trail`. `group` marks enable faceting/subplots. Encoding sets: `enter`, `update`, `exit`, `hover`.

### axes & legends
```json
"axes": [
  { "orient": "bottom", "scale": "x", "title": "Category",
    "labelAngle": -45, "grid": false },
  { "orient": "left", "scale": "y", "title": "Amount", "grid": true,
    "tickCount": 5, "format": "~s" }
],
"legends": [
  { "fill": "color", "title": "Category", "orient": "right",
    "encode": {"symbols": {"update": {"shape": {"value": "circle"}}}} }
]
```

### signals (interactivity / reactivity)
```json
"signals": [
  { "name": "hover", "value": null,
    "on": [ {"events":"rect:mouseover","update":"datum"},
            {"events":"rect:mouseout","update":"null"} ] },
  { "name": "barColor", "value": "steelblue" }
]
```
Signals are reactive variables driven by `events`; reference them in encodings as `{"signal":"hover ? 'red' : 'steelblue'"}`. Event streams support `[mousedown, mouseup] > mousemove` drag composition, throttling `{throttle:100}`, and `filter`.

## Chart Types
Vega has no "chart types" — you compose them from marks + scales. Any chart is achievable: bar, line, area, scatter, heatmap (rect), contour, arc/pie, treemap/pack/tree (hierarchy transforms + group marks), force-directed graph (`force` transform), choropleth/geo (`projections` + `geoshape`), wordcloud, streamgraph (stack with `offset:"wiggle"`), radial, sankey (via linkpath). The examples gallery is the catalog.

## Projections (geo)
```json
"projections": [
  { "name": "proj", "type": "albersUsa", "scale": 1000, "translate": [{"signal":"width/2"},{"signal":"height/2"}] }
],
"marks": [{ "type":"shape", "from":{"data":"states"}, "encode":{...},
            "transform":[{"type":"geoshape","projection":"proj"}] }]
```
Projection types: `albersUsa`, `mercator`, `orthographic`, `equalEarth`, `naturalEarth1`, `azimuthalEqualArea`, `conicConformal`, etc.

## How-To

### How to set colors / palette / theme
Color lives in a scale with a named scheme, or hard-coded in mark encodings.
```json
// 1) Categorical scheme scale referenced by a mark's fill
"scales": [{ "name":"color","type":"ordinal",
  "domain":{"data":"t","field":"cat"},
  "range":{"scheme":"tableau10"} }]
// mark: "fill": {"scale":"color","field":"cat"}

// 2) Sequential scheme with count/extent
"scales":[{"name":"heat","type":"linear","domain":{"data":"t","field":"v"},
  "range":{"scheme":"viridis"}}]

// 3) Custom explicit palette
"range": ["#4e79a7","#f28e2b","#e15759","#76b7b2"]

// 4) Signal-driven / conditional color in the mark
"fill": {"signal": "datum.v > 0 ? '#59a14f' : '#e15759'"}
```
Schemes: `category10/20`, `tableau10/20`, `viridis`, `magma`, `inferno`, `plasma`, `blues`, `greens`, `reds`, `blueorange`, `redblue`, `spectral`. Reverse with `{"scheme":"viridis","reverse":true}`. Global theming: pass a config object to `vega.parse(spec, config)` overriding `axis`, `legend`, `mark`, `range` defaults, or use the `vega-themes` package (`dark`, `excel`, `ggplot2`, `quartz`, `vox`, `fivethirtyeight`).

### How to add a hover highlight
```json
"marks":[{"type":"rect","from":{"data":"t"},"encode":{
  "update":{"fill":{"value":"steelblue"}},
  "hover":{"fill":{"value":"orange"}}}}]
```

### How to render server-side to SVG/PNG (Node)
```javascript
const vega = require('vega');
const view = new vega.View(vega.parse(spec), {renderer:'none'});
const svg = await view.toSVG();                 // string
const canvas = await view.toCanvas(); const png = canvas.toBuffer();  // needs `canvas`
```

### How to facet into small multiples
Wrap marks in a `group` mark with `from.facet`:
```json
{ "type":"group", "from":{"facet":{"data":"t","name":"cell","groupby":"region"}},
  "encode":{"enter":{"width":{"value":120},"height":{"value":120}}},
  "marks":[{"type":"rect","from":{"data":"cell"}, "encode":{...}}] }
```

## Do's and Don'ts

### ✅ Do
- Prototype in the online Vega Editor — it shows the data flow and errors live.
- Prefer Vega-Lite and eject to Vega only for interactions/layout it can't express (`vl.compile(spec)` gives you the Vega).
- Use `vega-embed` to load a spec with a toolbar/export in one call.
- Name every dataset and reference by name; keep transforms in the data block, not marks.

### ❌ Don't
- Don't hand-author full Vega for a standard bar/line — Vega-Lite is 5x shorter.
- Don't forget `"zero": true`/`"nice": true` on quantitative scales or bars will mislead.
- Don't reference a scale/field before defining it — parse errors are terse.
- Don't put large inline data in the spec you re-parse often; use `url` or `vega.changeset` updates.

## Styling, Theming & Customization
- **config object**: second arg to `vega.parse` sets defaults for `axis`, `axisX/Y`, `legend`, `title`, `mark`, `range` (default schemes), `background`, `padding`.
- **vega-themes**: `import {dark} from 'vega-themes'; vegaEmbed(el, spec, {theme:'dark'})`.
- Per-mark styling via encode `enter`/`update`; text marks for labels/annotations.

## Advanced Features
- **Interaction**: signals + event streams build brushing, panning, cross-filtering, tooltips.
- **Layouts**: force, tree/treemap/pack/partition (hierarchy), geo projections, contour, voronoi, wordcloud.
- **Streaming updates**: `view.change('table', vega.changeset().insert(rows).remove(pred)).run()`.
- **Expressions**: a sandboxed expression language (`datum.x`, `scale('y', v)`, `warn()`, `if()`) usable in signals/encodings.
- **vega-embed**: `vegaEmbed('#el', spec, {actions:true})` adds export-to-PNG/SVG and view-source.

## Common Pitfalls & Troubleshooting
- "Unrecognized scale/field" → you referenced before defining, or misnamed a dataset.
- Nothing renders → check mark `from.data` name matches a `data` entry; check width/height.
- Overlapping labels → `labelOverlap:"parity"`, `labelAngle`, or increase `tickCount` spacing.
- Big data slow → `sample` transform, Canvas renderer over SVG, aggregate before drawing.
- Colors wrong → domain not matching field type; ordinal vs linear scale mismatch.

## Best For / Avoid For
`reproducible-research`, `automated-reporting`, `bespoke-interactions`, `server-side-rendering`, `custom-layouts`, `data-pipelines` — choose Vega.
Avoid for: `quick-standard-charts` (Vega-Lite), `3D`, `imperative-fine-tuning` (D3), `non-technical-authoring`.

## See Also
- `vega-lite.md` — the higher-level grammar that compiles to Vega
- `d3_js.md` — imperative low-level alternative
- `plotly_js.md` — trace-based interactive charts
- `observable-plot.md` — concise grammar of graphics
- `../use-case/data-visualization.md`
