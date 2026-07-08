# Observable Plot — Concise grammar of graphics for the web

Observable Plot is a JavaScript visualization library from the makers of D3. A chart is `Plot.plot({marks, ...scales})` where **marks** (dot, line, barY, …) map data to geometry and Plot auto-generates scales, axes, and legends. It renders SVG, supports transforms (bin, group, stack, regression), faceting, and lightweight interactivity (tooltips, crosshair). It is far terser than D3 while remaining flexible.

**Current Version**: @observablehq/plot 0.6.x (current)  **License**: ISC (MIT-compatible)  **Bundle**: ~180KB min+gzip; depends on D3 v7

## Official Resources & Documentation
- Docs: https://observablehq.com/plot/
- API: https://github.com/observablehq/plot/blob/main/README.md
- Gallery: https://observablehq.com/@observablehq/plot-gallery
- Forum: https://talk.observablehq.com/c/plot/
- GitHub: https://github.com/observablehq/plot

## Installation & Setup
### Browser (ESM)
```html
<script type="module">
import * as Plot from "https://cdn.jsdelivr.net/npm/@observablehq/plot@0.6/+esm";
const chart = Plot.plot({ marks: [Plot.dot(data, {x:"a", y:"b"})] });
document.body.append(chart);
</script>
```
### NPM
```bash
npm install @observablehq/plot   # 0.6.x
npm install d3                    # peer: data helpers (timeParse, extent, ...)
```
```javascript
import * as Plot from "@observablehq/plot";
```
### Node SSR
```javascript
import {JSDOM} from "jsdom";
const {document} = new JSDOM("").window;
const svg = Plot.plot({document, marks:[Plot.barY(data,{x:"k",y:"v"})]});
```

## Core API Reference
`Plot.plot(options)` returns an SVG/HTML element. Key top-level options: `marks` (array), `x`/`y`/`color`/`r`/`opacity`/`symbol` (scale defs), `facet`, `fx`/`fy` (facet scales), `width`/`height`/`margin*`, `grid`, `inset`, `style`, `caption`, `document`.
```javascript
Plot.plot({
  width: 640, height: 400, marginLeft: 60, grid: true,
  x: { label: "GDP →", type: "log", tickFormat: "$,.0f" },
  y: { label: "↑ Life expectancy", domain: [50, 90] },
  color: { legend: true, scheme: "tableau10" },
  marks: [
    Plot.dot(data, { x: "gdp", y: "life", fill: "continent", r: "pop", tip: true }),
    Plot.ruleY([0])
  ]
});
```
Every mark takes `(data, channels)` where channels map a field name, an accessor `d => d.v`, or a constant.

## Marks (the geometry vocabulary)
- **Basic**: `dot`, `line`, `lineX`/`lineY`, `area`, `areaX`/`areaY`, `barX`/`barY`, `rectX`/`rectY`, `rect`, `cell`, `text`, `tick`/`tickX`/`tickY`, `rule`/`ruleX`/`ruleY`, `link`, `arrow`, `vector`, `image`, `frame`.
- **Statistical/transform marks**: `dotX`/`dotY`, `boxX`/`boxY`, `linearRegressionX`/`linearRegressionY`, `contour`, `density`, `hexgrid`, `raster`.
- **Geo**: `geo`, `sphere`, `graticule` (with a `projection` option).
- Marks compose by stacking in the `marks` array; later marks draw on top.

## Transforms
Wrap channel options in a transform to aggregate/reshape:
```javascript
Plot.rectY(data, Plot.binX({ y: "count" }, { x: "value", fill: "steelblue" }))   // histogram
Plot.barY(data, Plot.groupX({ y: "sum" }, { x: "cat", y: "amount" }))            // grouped sum
Plot.areaY(data, Plot.stackY({ x: "date", y: "value", fill: "series" }))         // stacked area
Plot.lineY(data, Plot.windowY(7, { x: "date", y: "price" }))                     // moving average
Plot.dot(data, Plot.map({ y: "cumsum" }, { x: "i", y: "delta" }))                // cumulative
```
Transform functions: `bin`/`binX`/`binY`, `group`/`groupX`/`groupY`/`groupZ`, `stackX`/`stackY`, `map`/`mapX`/`mapY`, `window`, `select`, `filter`, `sort`, `normalize`, `dodgeX`/`dodgeY` (beeswarm), `hexbin`, `shiftX`.

## Scales
Set via top-level keys `x`, `y`, `color`, `r`, `opacity`, `symbol`, `length`, `fx`, `fy`.
```javascript
x: { type: "utc", domain: [start, end], nice: true, grid: true, tickRotate: -45 }
y: { type: "linear", zero: true, percent: true, reverse: false }
color: { type: "ordinal", scheme: "category10", legend: true }  // or type "linear"/"diverging"
r: { range: [2, 20] }                                            // radius scale
```
Scale types: `linear`, `pow`, `log`, `symlog`, `sqrt`, `utc`, `time`, `ordinal`, `point`, `band`, `categorical`, `sequential`, `diverging`, `quantile`, `threshold`, `identity`.

## How-To

### How to set colors / palette / theme
```javascript
// 1) Constant color on a mark
Plot.line(data, { x:"date", y:"v", stroke:"#4e79a7" })

// 2) Color by a categorical field with a scheme
Plot.plot({
  color: { scheme: "tableau10", legend: true },
  marks: [ Plot.dot(data, { x:"a", y:"b", fill:"category" }) ]
})

// 3) Continuous / sequential
Plot.plot({ color:{ type:"linear", scheme:"viridis", legend:true },
  marks:[ Plot.dot(data,{x:"a",y:"b",fill:"value"}) ] })

// 4) Explicit domain→range map
color: { domain: ["A","B","C"], range: ["#4e79a7","#f28e2b","#e15759"] }

// 5) Diverging around a midpoint
color: { type:"diverging", scheme:"RdBu", pivot: 0 }
```
Schemes: `tableau10`, `category10`, `observable10`, `viridis`, `magma`, `blues`, `reds`, `spectral`, `rdbu`, `turbo`. Reverse with `reverse:true`. There is no global "theme" object — reuse a shared `options` object, or override the SVG via the `style` option (`style:{background:"#111", color:"#eee", fontFamily:"Inter"}`) for dark mode.

### How to make a histogram
```javascript
Plot.plot({ marks: [
  Plot.rectY(data, Plot.binX({ y: "count" }, { x: "value", thresholds: 30 })),
  Plot.ruleY([0])
]});
```

### How to build faceted small multiples
```javascript
Plot.plot({
  marginRight: 80,
  marks: [ Plot.dot(data, { x:"gdp", y:"life", fx:"continent", fill:"continent" }) ]
});
// fx/fy are facet scales; or use facet:{data, x:"continent"} + facet mark option
```

### How to add interactive tooltips
```javascript
Plot.plot({ marks: [
  Plot.dot(data, { x:"gdp", y:"life", fill:"continent",
    tip: true,                                   // hover tooltip
    channels: { country: "country" },            // extra fields in tip
    title: d => `${d.country}: ${d.life}y` })    // native title fallback
]});
// crosshair helper:
Plot.plot({ marks:[ Plot.lineY(data,{x:"date",y:"v"}), Plot.crosshairX(data,{x:"date",y:"v"}) ]});
```

### How to export the chart
```javascript
const chart = Plot.plot({...});           // an SVG element
const svgText = new XMLSerializer().serializeToString(chart);
// For PNG, draw the serialized SVG onto a canvas and canvas.toBlob(...).
```

## Do's and Don'ts

### ✅ Do
- Give Plot tidy arrays of objects; reference fields by name.
- Add `Plot.ruleY([0])` / `Plot.ruleX([0])` to anchor bar/area baselines.
- Use transforms (`binX`, `groupX`, `stackY`) instead of pre-aggregating.
- Reuse one `options` object across charts for a consistent look (Plot has no theme system).

### ❌ Don't
- Don't render >100k SVG points — sample, aggregate (`bin`/`hexbin`), or switch to canvas/WebGL libs.
- Don't forget marks are ordered — a fill mark after a line will cover it.
- Don't expect rich built-in interaction (zoom/pan/brush) — Plot's interactivity is limited to tips/crosshair; wire the rest yourself or use Plotly/Vega.
- Don't set both `fill` constant and `fill` field — pick one per mark.

## Styling, Theming & Customization
- `style`: object or CSS string applied to the root SVG (background, color, font).
- Per-mark: `stroke`, `fill`, `strokeWidth`, `strokeDasharray`, `opacity`, `r`, `symbol`.
- Axis control via scale options: `label`, `tickFormat`, `tickRotate`, `ticks`, `grid`, `line`, `inset`.
- `Plot.legend({color:...})` renders a standalone legend element.

## Advanced Features
- **Faceting**: `fx`/`fy` facet scales or `facet` mark option for small multiples with shared scales.
- **Projections**: `projection: "albers-usa" | "mercator" | "equal-earth" | {...}` with `geo`/`sphere`/`graticule` marks for maps.
- **Statistical marks**: `linearRegressionY`, `density`, `contour`, `boxY`, `hexbin`.
- **Composition**: any number of marks share the same scales; combine bars + lines + rules freely.
- **Framework use**: returns a DOM node — drop into React (`ref.replaceChildren(chart)`), Vue, or Svelte.

## Integration Notes
- **React**: Plot returns a DOM node — render in a `useEffect` and `containerRef.current.replaceChildren(chart)`; recreate on data change.
- **Observable notebooks**: first-class — `Plot.plot({...})` is a cell value; `d3.csv(url, d3.autoType)` loads typed data.
- **Vanilla/Svelte/Vue**: append the returned node; there is no persistent instance to update — rebuild the chart on state change.
- **d3 interop**: import `d3` for `timeParse`, `extent`, `rollup`, `autoType`, and scales when preparing data.

### How to prepare tidy, typed data
```javascript
const rows = (await d3.csv(url)).map(d => ({
  date: d3.utcParse("%Y-%m-%d")(d.date),
  value: +d.value,
  category: d.category?.trim()
})).filter(d => d.date && !isNaN(d.value));
```

## Common Pitfalls & Troubleshooting
- Empty chart → wrong field names or non-numeric strings; coerce with `+d.value`.
- Bars float off baseline → add `Plot.ruleY([0])` and ensure `y` scale `zero:true`.
- Dates plotted as categories → parse to `Date` (d3.timeParse) and set `x.type:"utc"`.
- Legend missing → set `color:{legend:true}` (or `r:{legend:true}` for size).
- Labels clipped → increase `marginLeft`/`marginBottom`.

## Best For / Avoid For
`exploratory-data-analysis`, `statistical-charts`, `small-multiples`, `publication-svg`, `dashboard-components`, `time-series` — choose Observable Plot.
Avoid for: `>100k-points`, `heavy-zoom-pan-brush`, `3D`, `deep-custom-interaction` (D3), `no-D3-dependency` builds.

## See Also
- `vega-lite.md` — JSON declarative grammar (similar altitude)
- `d3_js.md` — the low-level library Plot builds on
- `chart_js.md` / `plotly_js.md` — pre-built interactive chart types
- `../use-case/data-visualization.md`
