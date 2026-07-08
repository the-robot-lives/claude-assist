# JSXGraph — Interactive Geometry & Function Plotting

JSXGraph is a dependency-free JavaScript library for interactive geometry, function plotting,
charting, and data visualization, rendering to SVG (or Canvas/VML). Unlike embedded
calculators (Desmos/GeoGebra), it is an *open-source library you script directly*: you create
a board, then add typed elements (points, lines, circles, curves, sliders) whose geometric
dependencies update live as the user drags them. Ideal for math education widgets, dynamic
constructions, and lightweight scientific plots.

**Current Version**: 1.10.x  **License**: LGPL-3.0 / MIT (dual)
**Bundle**: ~180KB min+gzip, zero dependencies  **Runtime**: Browser (SVG default); Node via headless DOM

## Official Resources & Documentation
- Site: https://jsxgraph.uni-bayreuth.de/
- Reference: https://jsxgraph.uni-bayreuth.de/docs/
- Wiki/examples: https://jsxgraph.uni-bayreuth.de/wiki/
- GitHub: https://github.com/jsxgraph/jsxgraph
- npm: https://www.npmjs.com/package/jsxgraph

## Installation & Setup

### CDN
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/jsxgraph/distrib/jsxgraph.css" />
<script src="https://cdn.jsdelivr.net/npm/jsxgraph/distrib/jsxgraphcore.js"></script>
<div id="jxgbox" class="jxgbox" style="width:500px;height:500px;"></div>
```

### Package manager
```bash
npm install jsxgraph
```
```javascript
import JXG from 'jsxgraph';
import 'jsxgraph/distrib/jsxgraph.css';
```

## Core API Reference

The entry point is a **board** bound to a container. You then `board.create(type, parents,
attributes)` where `parents` are the defining objects (coordinates, other elements, or
functions) and `attributes` style/behavior. Dependent elements recompute automatically.

### Initialize a board
```javascript
const board = JXG.JSXGraph.initBoard('jxgbox', {
  boundingbox: [-5, 5, 5, -5],   // [xMin, yMax, xMax, yMin]
  axis: true,
  grid: true,
  showCopyright: false,
  keepaspectratio: true,
  pan: { enabled: true }, zoom: { wheel: true },
});
```

### Points, lines, segments
```javascript
const A = board.create('point', [1, 1], { name: 'A', size: 4, color: '#c0392b' });
const B = board.create('point', [3, 2], { name: 'B' });
const line = board.create('line', [A, B], { strokeColor: 'blue', strokeWidth: 2 });
const seg  = board.create('segment', [A, B], { dash: 2 });
const perp = board.create('perpendicular', [line, A]);
```

### Circles, polygons, angles
```javascript
const circle = board.create('circle', [A, 2], { fillColor: 'yellow', fillOpacity: 0.3 });
const poly   = board.create('polygon', [[0,0], [2,0], [1,2]], { fillColor: '#3498db' });
const ang    = board.create('angle', [A, B, [4,1]], { radius: 1 });
```

### Function graphs & curves
```javascript
const f = board.create('functiongraph',
  [ (x) => Math.sin(x) * Math.exp(-x / 5), -10, 10 ],
  { strokeWidth: 2, strokeColor: 'red' });

// Numeric derivative of f:
const df = board.create('functiongraph',
  [ JXG.Math.Numerics.D(f.Y), -10, 10 ],
  { dash: 2, strokeColor: 'green' });

// Parametric curve [x(t), y(t), tMin, tMax]:
const curve = board.create('curve',
  [ (t) => Math.cos(t), (t) => Math.sin(t), 0, 2 * Math.PI ],
  { strokeColor: '#8e44ad' });
```

### Sliders (interactive parameters)
```javascript
// [ [x1,y], [x2,y], [min, start, max] ]
const a = board.create('slider', [[-3, 4], [3, 4], [0, 1, 5]], { name: 'a' });
board.create('functiongraph', [ (x) => a.Value() * x * x, -5, 5 ], { strokeColor: 'orange' });
```

### Text, integrals, intersections
```javascript
board.create('text', [1, -2, () => 'a = ' + a.Value().toFixed(2)]);
board.create('integral', [[-2, 2], f], { fillColor: 'blue', fillOpacity: 0.2 });
const P = board.create('intersection', [line, circle, 0]); // 0th intersection point
```

### Live updates & events
```javascript
board.on('update', () => { /* runs on any change */ });
A.on('drag', () => console.log('A at', A.X(), A.Y()));
board.update();                    // force recompute/redraw
board.suspendUpdate();             // batch many creates…
board.unsuspendUpdate();           // …then redraw once
```

## Element Types Overview
- **Geometry**: point, glider (constrained point), line, segment, ray, circle, ellipse,
  conic, polygon, angle, arc, sector, midpoint, perpendicular, parallel, bisector, tangent.
- **Analysis**: functiongraph, curve (parametric/polar), integral, riemannsum, derivative,
  tangent, slopefield.
- **Charts**: chart (bar/line/pie/spline), from data arrays.
- **Controls**: slider, button, checkbox, input, transform (translate/rotate/reflect/scale).

## How-To (worked recipes)

### How to color and style elements
Attributes control everything: `strokeColor`, `strokeWidth`, `fillColor`, `fillOpacity`,
`dash`, `size`, `face`. Functions may return dynamic values.
```javascript
board.create('circle', [[0,0], 2], {
  strokeColor: '#2980b9', strokeWidth: 3,
  fillColor: '#2980b9', fillOpacity: 0.15,
});
board.create('point', [2, 1], { face: 'cross', size: 6, strokeColor: '#c0392b' });
// dynamic color:
board.create('point', [1, 3], { color: () => (a.Value() > 2 ? 'red' : 'green') });
```

### How to plot a function and its derivative
```javascript
const g = board.create('functiongraph', [ (x) => x*x*x - 3*x, -3, 3 ], { strokeColor: 'navy' });
board.create('functiongraph', [ JXG.Math.Numerics.D(g.Y), -3, 3 ], { dash: 2, strokeColor: 'crimson' });
```

### How to build a slider-driven interactive
```javascript
const k = board.create('slider', [[-4, 4.5], [0, 4.5], [-3, 1, 3]], { name: 'k' });
board.create('curve', [
  (t) => k.Value() * Math.cos(t),
  (t) => k.Value() * Math.sin(t),
  0, 2 * Math.PI
], { strokeWidth: 2, strokeColor: '#16a085' });
```

### How to draw a bar chart from data
```javascript
board.create('chart', [[1,2,3,4,5], [3,5,2,6,4]], {
  chartStyle: 'bar', width: 0.8,
  colors: ['#3498db','#e74c3c','#2ecc71','#f39c12','#9b59b6'],
});
```

## Do's and Don'ts

### ✅ Do
- Define `boundingbox` as `[xMin, yMax, xMax, yMin]` (note the y order) to frame the view.
- Build dependent elements from existing ones (`line` from two points) so dragging updates everything.
- Wrap many `create` calls in `suspendUpdate()`/`unsuspendUpdate()` for performance.
- Use functions in attributes/parents for live, data-driven values (`() => a.Value()`).
- Include `jsxgraph.css` — dragging, cursors, and layout depend on it.

### ❌ Don't
- Don't reverse the `boundingbox` y-order; `[-5,5,5,-5]` means top-left to bottom-right.
- Don't recreate elements on every frame to "update" — mutate parents/values and call `board.update()`.
- Don't forget `keepaspectratio` if circles look like ellipses (non-square container).
- Don't add thousands of individual points for a curve — use `functiongraph`/`curve` (sampled).
- Don't script before the container exists; init the board after the DOM node is present.

## Styling, Theming & Customization
- **Per-element attributes**: `strokeColor`, `fillColor`, `fillOpacity`, `strokeWidth`, `dash`,
  `size`, `face` (o, x, +, cross, diamond, triangle), `label`, `visible`, `fixed`.
- **Board options**: `axis`, `grid`, `defaultAxes` styling, `showNavigation`, `showCopyright`.
- **Global defaults**: `JXG.Options.point.strokeColor = …` before board creation.
- **Highlight styles**: `highlightStrokeColor`, `highlightFillColor` for hover states.

## Advanced Features
- **Constrained points (gliders)** that slide along a curve/line.
- **Transforms**: `board.create('transform', [angle, center], { type: 'rotate' })` + apply to elements.
- **Numerics**: `JXG.Math.Numerics` (derivatives, roots, integration, regression, splines).
- **Turtle graphics** and **L-systems** for generative drawing.
- **Charts** (bar/line/pie/spline) and **slope fields / ODE** plotting.
- **Export**: SVG string via the board's renderer; screenshot to PNG with helper code.

## Common Pitfalls & Troubleshooting
- **Circles look oval** → set `keepaspectratio: true` or a square container.
- **Nothing appears** → wrong `boundingbox` order, or container has no size.
- **Drag doesn't update dependents** → element was created from raw coords, not from the parent objects.
- **Sluggish with many elements** → batch with `suspendUpdate`/`unsuspendUpdate`; reduce curve sample density.
- **Missing interactivity/styles** → `jsxgraph.css` not loaded.

## Framework Integration

### React wrapper
```jsx
import { useEffect, useRef } from 'react';
import JXG from 'jsxgraph';
import 'jsxgraph/distrib/jsxgraph.css';

function Board({ build }) {                 // build(board) sets up the construction
  const hostRef = useRef(null);
  useEffect(() => {
    const id = 'jxg-' + Math.random().toString(36).slice(2);
    hostRef.current.id = id;
    const board = JXG.JSXGraph.initBoard(id, { boundingbox: [-5,5,5,-5], axis: true });
    build?.(board);
    return () => JXG.JSXGraph.freeBoard(board);   // free the board on unmount
  }, [build]);
  return <div ref={hostRef} className="jxgbox" style={{ width: 500, height: 500 }} />;
}
```

### How to export the board as an image
```javascript
// SVG string from the renderer, or dump to PNG via canvas:
const svg = board.renderer.dumpToDataURI ? board.renderer.dumpToDataURI() : null;
// Simpler: JXG can dump SVG source
const svgSource = new XMLSerializer().serializeToString(board.containerObj.querySelector('svg'));
```

## Integration Notes
- **React/Vue**: init board in a mount effect after the ref exists; `JXG.JSXGraph.freeBoard(board)` on unmount.
- Pair with [katex](katex.md)/[mathjax](mathjax.md) for labels/prose; JSXGraph text supports LaTeX when a math renderer is present (`useMathJax`/`useKatex`).
- Lighter and more scriptable than [geogebra-api](geogebra-api.md); more geometry-focused than [desmos-api](desmos-api.md).

## Best For / Avoid For
`interactive-geometry`, `function-plotting`, `math-widgets`, `education`, `dynamic-constructions`,
`open-source`, `embeddable` — choose JSXGraph when you want a scriptable, dependency-free
geometry/plotting library you fully control.
Avoid for: turnkey calculator UX ([desmos-api](desmos-api.md)), CAS/3D-heavy math
([geogebra-api](geogebra-api.md)), 3D surfaces ([mathbox](mathbox.md)), or large-scale dataviz (use a chart lib).

## See Also
- [desmos-api](desmos-api.md) — turnkey graphing calculator embed
- [geogebra-api](geogebra-api.md) — full dynamic-math app with CAS/3D
- [mathbox](mathbox.md) — 3D mathematical visualization
- [katex](katex.md) / [mathjax](mathjax.md) — typeset labels and prose
- Use case: [../use-case/mathematical-scientific.md](../use-case/mathematical-scientific.md)
