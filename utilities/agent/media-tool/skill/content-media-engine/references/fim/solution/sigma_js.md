---
name: Sigma.js
description: High-performance WebGL graph rendering library for large-scale network visualization
docs: https://www.sigmajs.org/
examples: https://www.sigmajs.org/demo/
---

# Sigma.js — WebGL renderer for large graphs (graphology-backed)

Sigma.js is a rendering-only library: it draws a graph onto WebGL, handling camera,
pan/zoom, hover, and picking, but it does **not** own the graph data model. The data
lives in a separate [graphology](https://graphology.github.io/) `Graph` instance, and
graphology's companion packages provide layouts, metrics, and import/export. This split
is the single most important thing to understand: you build/mutate the graph with
graphology, and Sigma renders it. WebGL rendering lets it handle 10k+ nodes smoothly
where canvas/SVG libraries stall.

**Current Version**: sigma 3.x + graphology 0.25.x (current majors)  **License**: MIT  **Runtime**: browser WebGL; scales to tens of thousands of nodes

## Official Resources & Documentation
- Site + docs: https://www.sigmajs.org/
- Live demos: https://www.sigmajs.org/demo/
- Sigma GitHub: https://github.com/jacomyal/sigma.js
- graphology docs: https://graphology.github.io/
- npm: https://www.npmjs.com/package/sigma

## Installation & Setup

### Package manager
```bash
npm install sigma graphology
# common companions:
npm install graphology-layout graphology-layout-forceatlas2 graphology-gexf
```

### CDN / browser
```html
<script src="https://cdn.jsdelivr.net/npm/graphology@0.25.4/dist/graphology.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sigma@3/dist/sigma.min.js"></script>
```

### Import styles (ESM)
```javascript
import Graph from 'graphology';
import Sigma from 'sigma';
import forceAtlas2 from 'graphology-layout-forceatlas2';
```

## Core Syntax / API Reference

### The graph model (graphology)
Nodes and edges carry an **attributes** object. Sigma reads a fixed set of reserved
attribute names for rendering: on nodes `x`, `y`, `size`, `color`, `label`, `type`,
`hidden`, `zIndex`, `image`; on edges `size`, `color`, `label`, `type`, `hidden`.
```javascript
const graph = new Graph();                 // or new Graph({ type: 'directed', multi: false })
graph.addNode('a', { x: 0,   y: 0,  size: 12, label: 'Alpha', color: '#4f8ef7' });
graph.addNode('b', { x: 10,  y: 4,  size: 8,  label: 'Beta',  color: '#e0607e' });
graph.addEdge('a', 'b', { size: 2, color: '#ccc', label: 'links' });
// directed variants: graph.addDirectedEdge / addEdgeWithKey('e1', 'a', 'b', {...})
```
Critical: Sigma will not position nodes for you. Every node needs `x`/`y` (from a layout,
from your data, or random) or it renders at the origin.

Reading/mutating attributes:
```javascript
graph.getNodeAttribute('a', 'size');
graph.setNodeAttribute('a', 'color', '#f00');
graph.updateNodeAttribute('a', 'size', (s) => s * 2);
graph.forEachNode((key, attrs) => { /* ... */ });
graph.order;  // node count   graph.size;  // edge count
```

### The renderer
```javascript
const container = document.getElementById('container'); // must have a height
const renderer = new Sigma(graph, container, {
  renderLabels: true,
  renderEdgeLabels: false,
  defaultNodeColor: '#999',
  defaultEdgeColor: '#e0e0e0',
  labelColor: { color: '#333' },
  labelSize: 12,
  labelRenderedSizeThreshold: 6,   // hide labels for small nodes
  minCameraRatio: 0.1,
  maxCameraRatio: 10,
});
```

### Reducers — dynamic per-render styling
Reducers are the idiomatic way to change appearance without mutating the graph (for
hover, search, filtering). They run every frame and return the effective display attrs:
```javascript
renderer.setSetting('nodeReducer', (node, data) => {
  const res = { ...data };
  if (node === hoveredNode) { res.color = '#f39c12'; res.zIndex = 1; }
  if (state.searchMiss.has(node)) { res.label = ''; res.color = '#eee'; }
  return res;
});
renderer.setSetting('edgeReducer', (edge, data) => {
  const res = { ...data };
  if (!state.active) res.hidden = false;
  return res;
});
```

### Camera & interaction
```javascript
const camera = renderer.getCamera();
camera.animatedZoom();  camera.animatedUnzoom();  camera.animatedReset();
camera.goto({ x: 0.5, y: 0.5, ratio: 1 }, { duration: 500 });
```

### Events
```javascript
renderer.on('clickNode', ({ node }) => select(node));
renderer.on('enterNode', ({ node }) => { hoveredNode = node; renderer.refresh(); });
renderer.on('leaveNode', () => { hoveredNode = null; renderer.refresh(); });
renderer.on('clickStage', () => clearSelection());
```
Call `renderer.refresh()` after changing reducer state or graph data to repaint.

## Layouts (graphology packages)
Sigma has none built in — you assign `x`/`y` via graphology layouts:
- **ForceAtlas2** (`graphology-layout-forceatlas2`): the workhorse force layout.
- **Circular / random** (`graphology-layout`): `circular.assign(graph)`, `random.assign(graph)`.
- **noverlap** (`graphology-layout-noverlap`): overlap removal pass.
- **ForceAtlas2 as a worker** (`graphology-layout-forceatlas2/worker`): non-blocking, live-animating layout via `FA2Layout`.

```javascript
import forceAtlas2 from 'graphology-layout-forceatlas2';
const settings = forceAtlas2.inferSettings(graph);
forceAtlas2.assign(graph, { iterations: 200, settings }); // writes x/y onto nodes
```

## How-To (worked recipes)

### How to color and style nodes & edges
Static styling = write reserved attributes onto the graph. Dynamic styling = reducers.
```javascript
// static: color by category, size by degree
graph.forEachNode((n, a) => {
  graph.setNodeAttribute(n, 'color', CATEGORY_COLORS[a.category] ?? '#999');
  graph.setNodeAttribute(n, 'size', 4 + Math.sqrt(graph.degree(n)) * 2);
});
graph.forEachEdge((e) => graph.setEdgeAttribute(e, 'color', '#ddd'));

// dynamic: dim everything except a selected node's neighborhood
renderer.setSetting('nodeReducer', (node, data) => {
  if (!selected) return data;
  const near = node === selected || graph.areNeighbors(selected, node);
  return near ? data : { ...data, color: '#eee', label: '' };
});
renderer.refresh();
```

### How to lay out a graph with ForceAtlas2
```javascript
import forceAtlas2 from 'graphology-layout-forceatlas2';
import circular from 'graphology-layout/circular';
circular.assign(graph);                         // seed positions first
forceAtlas2.assign(graph, { iterations: 300, settings: forceAtlas2.inferSettings(graph) });
```

### How to load a GEXF file (from Gephi)
```javascript
import { parse } from 'graphology-gexf/browser';
const graph = parse(Graph, await (await fetch('network.gexf')).text());
new Sigma(graph, container);   // GEXF carries x/y/color/size from Gephi
```

### How to implement search + highlight
```javascript
function search(term) {
  const hits = new Set();
  graph.forEachNode((n, a) => { if (a.label?.toLowerCase().includes(term)) hits.add(n); });
  renderer.setSetting('nodeReducer', (n, d) => hits.has(n) ? { ...d, zIndex: 1 } : { ...d, color: '#eee', label: '' });
  renderer.refresh();
}
```

### How to register custom node/edge programs (shapes)
Sigma's visual vocabulary is extended by registering WebGL "programs" keyed to the `type`
attribute. The official add-on packages cover the common cases:
```javascript
import { NodeImageProgram } from '@sigma/node-image';
import { EdgeCurvedArrowProgram } from '@sigma/edge-curve';

const renderer = new Sigma(graph, container, {
  defaultNodeType: 'circle',
  nodeProgramClasses: { image: NodeImageProgram },   // nodes with type:'image'
  edgeProgramClasses: { curved: EdgeCurvedArrowProgram }, // edges with type:'curved'
});
graph.addNode('u', { x: 0, y: 0, size: 20, type: 'image', image: '/avatar.png' });
graph.addEdge('u', 'v', { type: 'curved', size: 2 });
```

## Settings Reference
Frequently-used Sigma settings (2nd/3rd arg): rendering — `renderLabels`,
`renderEdgeLabels`, `defaultNodeColor`, `defaultEdgeColor`, `defaultNodeType`,
`defaultEdgeType`; labels — `labelFont`, `labelSize`, `labelWeight`, `labelColor`,
`labelDensity`, `labelGridCellSize`, `labelRenderedSizeThreshold`; camera —
`minCameraRatio`, `maxCameraRatio`, `zoomToSizeRatioFunction`; interaction —
`enableEdgeEvents`, `allowInvalidContainer`; reducers — `nodeReducer`, `edgeReducer`;
custom draw hooks — `defaultDrawNodeHover`, `defaultDrawNodeLabel`, `defaultDrawEdgeLabel`.
Set any at runtime with `renderer.setSetting(key, value)` then `renderer.refresh()`.

## Do's and Don'ts

### ✅ Do
- Assign `x`/`y` (via a layout or your data) before rendering — Sigma will not do it.
- Use **reducers** for hover/search/filter state; mutate the graph only for durable data changes.
- Use the ForceAtlas2 **worker** for live layout so the main thread stays responsive.
- Call `renderer.refresh()` after reducer-state or data changes.

### ❌ Don't
- Don't expect built-in layouts or algorithms from Sigma — reach for graphology packages.
- Don't mutate node attributes every frame for hover effects; that's what reducers are for (no graph churn).
- Don't render into a zero-height container — WebGL canvas needs explicit dimensions.
- Don't store huge label strings on every node if `renderLabels` is on at low zoom — labels are the main text-rendering cost.

## Styling, Theming & Customization
- **Node/edge types**: `type` selects a WebGL program. Built-ins include node `circle`
  (default) and `image`, and edge `line`/`arrow`/`curve` depending on registered programs.
- **Custom programs**: register renderers with `nodeProgramClasses`/`edgeProgramClasses`
  in Sigma settings for custom shapes (e.g. `@sigma/node-image`, `@sigma/edge-curve`).
- **Labels**: `labelFont`, `labelSize`, `labelWeight`, `labelColor`, and
  `labelRenderedSizeThreshold` (only label nodes above a pixel size) control the label layer.
- **Dark theme**: set `defaultNodeColor`/`defaultEdgeColor`/`labelColor` to light values and give the container a dark background via CSS.

## Advanced Features
- **Edge curvature & arrows**: via `@sigma/edge-curve` and the arrow edge program for directed graphs.
- **Node images**: `@sigma/node-image` renders avatars/icons inside nodes.
- **Hovered/highlighted rendering hooks**: `drawHover`, `drawLabel` settings accept custom canvas callbacks (the label/hover layer is 2D canvas on top of WebGL).
- **Export**: use `@sigma/export-image` or read from `renderer.getCanvases()` to snapshot to PNG.

## Common Pitfalls & Troubleshooting
- **Nodes stacked at origin**: you forgot to run a layout / set `x`/`y`.
- **Nothing renders**: container has no height, or graphology and sigma major versions mismatch (sigma 3 requires graphology ≥0.25).
- **Labels missing**: `renderLabels` false, or nodes below `labelRenderedSizeThreshold`.
- **Reducer changes ignored**: you didn't call `renderer.refresh()`.
- **Old tutorials use `new Sigma({ graph, container })`**: sigma 2/3 signature is `new Sigma(graph, container, settings)`.

## Best For / Avoid For
`large-graphs`, `webgl`, `social-graph`, `knowledge-graph`, `real-time-network-monitoring`, `10k-plus-nodes` — pick Sigma when scale and smooth pan/zoom matter most.
Avoid for: small diagrams where you want batteries included (use `vis_js`), rich per-element DOM/SVG interactivity, or when you don't want the graphology dependency + layout wiring.

## Performance & Limits
- **Built for scale**: WebGL rendering handles 10k–100k+ nodes for pan/zoom where canvas/SVG libraries stall. The renderer is the fast part.
- **The layout is the bottleneck**, not rendering. Synchronous `forceAtlas2.assign` blocks the main thread proportional to `iterations × edges`. For big graphs use the **worker** so the UI stays responsive:
  ```javascript
  import FA2Layout from 'graphology-layout-forceatlas2/worker';
  const layout = new FA2Layout(graph, { settings: forceAtlas2.inferSettings(graph) });
  layout.start(); // animates live; layout.stop() when settled
  ```
- **Label rendering** is the main per-frame text cost. Raise `labelRenderedSizeThreshold` and set `renderLabels:false` while panning big graphs, then re-enable.
- **Reducers run every frame** for every visible element — keep them cheap (no allocations in the hot path beyond the returned object; precompute sets outside).
- **Edges dominate** memory/draw when the graph is dense; consider hiding edges below a zoom level via `edgeReducer`.

## Integration Notes
- **React**: use `@react-sigma/core` — `<SigmaContainer>` plus hooks (`useSigma`, `useLoadGraph`, `useRegisterEvents`) wrap the imperative renderer. Or manage a `Sigma` instance in a `useEffect` yourself and `renderer.kill()` on unmount.
- **graphology ecosystem**: metrics (`graphology-metrics` — centralities, density), communities (`graphology-communities-louvain`), traversal (`graphology-traversal`), and shortest paths all operate on the same `Graph` you render — analyze and visualize with one model.
- **Interchange**: `graphology-gexf` (Gephi round-trip) and `graphology-graphml` import/export let you move graphs between Gephi, NetworkX, and the browser.
- **SSR**: WebGL needs a real canvas; instantiate client-side only.

## See Also
- `cytoscape_js.md` — full graph library with built-in algorithms and SVG-like styling.
- `vis_js.md` — physics + interaction out of the box for small/medium graphs.
- `cola_js.md` / `springy_js.md` — layout engines you can feed positions from.
- `gephi.md` — desktop tool that exports GEXF (Sigma reads it via graphology-gexf).
- `../use-case/networks-graphs.md` — choosing among network/graph tools.
