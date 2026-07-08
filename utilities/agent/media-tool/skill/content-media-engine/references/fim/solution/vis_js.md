---
name: Vis.js Network
description: Interactive network visualization library with physics simulation and clustering
docs: https://visjs.github.io/vis-network/docs/network/
examples: https://visjs.github.io/vis-network/examples/
---

# vis-network — interactive physics-driven network graphs

vis-network (the network module of the vis.js family) renders interactive node-link
diagrams onto an HTML5 `<canvas>`. It ships with a built-in physics engine, several
force solvers, hierarchical layout, clustering, and a full manipulation UI (add/edit/
delete nodes and edges). You give it two `DataSet`s — `nodes` and `edges` — plus an
`options` object, and it handles layout, drag, zoom, hover, and selection for you.

**Current Version**: vis-network 9.x (current major)  **License**: MIT / Apache-2.0 (dual)  **Runtime**: browser canvas; ~1MB standalone bundle (physics is CPU-bound, degrades past ~2–3k nodes)

## Official Resources & Documentation
- Docs: https://visjs.github.io/vis-network/docs/network/
- Examples gallery: https://visjs.github.io/vis-network/examples/
- GitHub: https://github.com/visjs/vis-network
- npm: https://www.npmjs.com/package/vis-network
- DataSet docs (vis-data): https://visjs.github.io/vis-data/data/dataset.html

## Installation & Setup

### Package manager
```bash
npm install vis-network vis-data
```

### CDN / browser
```html
<link href="https://cdn.jsdelivr.net/npm/vis-network@9/dist/dist/vis-network.min.css" rel="stylesheet" />
<script src="https://cdn.jsdelivr.net/npm/vis-network@9/standalone/umd/vis-network.min.js"></script>
```
The `standalone` build bundles `vis-data`, so `vis.Network` and `vis.DataSet` are both
on the global `vis`. The peer build (`dist/vis-network.min.js`) expects you to load
`vis-data` separately.

### Import styles (ESM)
```javascript
import { Network, DataSet } from 'vis-network/standalone';
// or split: import { Network } from 'vis-network'; import { DataSet } from 'vis-data';
```

## Core Syntax / API Reference

### Data model — nodes
A node needs a unique `id`. Every other field is a visual/behavioral property.
```javascript
const nodes = new DataSet([
  { id: 1, label: 'Server', group: 'infra', shape: 'box', color: '#4f8ef7' },
  { id: 2, label: 'DB', shape: 'database', title: 'PostgreSQL' }, // title = hover tooltip
  { id: 3, label: 'Cache', shape: 'dot', size: 25, value: 40 },   // value → scaled size
]);
```
Key node fields: `id`, `label`, `title` (HTML/text tooltip), `group`, `shape`, `color`
(string or `{background, border, highlight, hover}`), `size` (for scalable shapes),
`value` (feeds the size scaler), `x`/`y` (fixed position), `fixed` (`{x,y}` booleans),
`hidden`, `physics` (bool — exclude from simulation), `mass`, `font`, `image`, `shapeProperties`.

Node `shape` values: `ellipse`, `circle`, `box`, `text`, `database`, `diamond`, `dot`,
`star`, `triangle`, `triangleDown`, `hexagon`, `square`, plus `image`, `circularImage`,
`icon`, and `custom`. Note: `dot`/`circle` differ — `circle` grows to fit the label,
`dot` uses `size`/`value`.

### Data model — edges
```javascript
const edges = new DataSet([
  { from: 1, to: 2, arrows: 'to', label: 'writes', color: { color: '#888' } },
  { from: 1, to: 3, arrows: 'to;from', dashes: true, width: 3 },
  { from: 2, to: 3, arrows: { to: { type: 'arrow', scaleFactor: 1.2 } }, smooth: { type: 'curvedCW' } },
]);
```
Key edge fields: `from`, `to`, `id`, `label`, `title`, `arrows` (`'to'`, `'from'`,
`'middle'`, or object per side), `color` (`{color, highlight, hover, opacity, inherit}`),
`width`, `value` (scales width), `dashes` (bool or `[dash, gap]`), `smooth`
(`{enabled, type, roundness}`), `length` (spring rest length), `font`, `hidden`, `physics`.

### Instantiation
```javascript
const container = document.getElementById('network');
const network = new vis.Network(container, { nodes, edges }, options);
```

### Options object (top-level keys)
```javascript
const options = {
  nodes:   { shape: 'dot', size: 16, font: { size: 14, color: '#222' }, borderWidth: 2 },
  edges:   { width: 1, color: { inherit: 'from' }, smooth: { type: 'dynamic' } },
  groups:  { infra: { color: '#4f8ef7', shape: 'box' }, users: { color: '#e0607e' } },
  layout:  { improvedLayout: true, randomSeed: 2 },
  physics: { enabled: true, solver: 'forceAtlas2Based', stabilization: { iterations: 200 } },
  interaction: { hover: true, tooltipDelay: 200, zoomView: true, dragView: true, multiselect: true },
  manipulation: { enabled: false },
};
```
Options set on `nodes`/`edges` are defaults; per-element fields in the DataSet override them.

### Physics solvers
`physics.solver` selects the force model: `barnesHut` (default, general purpose,
gravitational), `forceAtlas2Based` (good for community structure), `repulsion`
(simple), and `hierarchicalRepulsion` (only for hierarchical layout). Each has its own
tuning block, e.g. `physics: { barnesHut: { gravitationalConstant: -8000, springLength: 120, avoidOverlap: 0.2 } }`.

### Events & methods
```javascript
network.on('click', (params) => console.log('nodes', params.nodes, 'edges', params.edges));
network.on('selectNode', (p) => highlight(p.nodes[0]));
network.on('hoverNode', (p) => showCard(p.node));
network.on('stabilizationIterationsDone', () => network.setOptions({ physics: false }));

network.fit({ animation: true });        // zoom to fit all
network.focus(1, { scale: 1.5, animation: true });
network.selectNodes([1, 2]);
network.setData({ nodes, edges });       // full replace
nodes.update({ id: 1, color: '#f00' });  // live single-node update
network.cluster({ /* options */ });      // collapse a set into one node
```
Live edits go through the DataSet (`nodes.add/update/remove`), not the network — the
network subscribes to DataSet changes and re-renders automatically.

## Supported Layouts & Diagram Types
- **Force-directed** (default): physics-driven organic placement.
- **Hierarchical**: `layout: { hierarchical: { enabled: true, direction: 'UD', sortMethod: 'directed', levelSeparation: 150 } }` — directions `UD`, `DU`, `LR`, `RL`. Good for org charts, DAGs, dependency trees.
- **Fixed/manual**: give nodes `x`/`y` and set `physics: false`.
- **Clustered**: collapse subgraphs into cluster nodes for large graphs.

## How-To (worked recipes)

### How to color and style nodes & edges
Three levels, from broad to specific: global defaults → group styles → per-element fields.
```javascript
const options = {
  nodes: { color: { background: '#eef', border: '#88a', highlight: { background: '#ffd' } } },
  edges: { color: { color: '#bbb', highlight: '#f39c12' }, width: 1 },
  groups: {
    critical: { color: { background: '#e74c3c', border: '#c0392b' }, shape: 'diamond' },
    normal:   { color: { background: '#2ecc71', border: '#27ae60' } },
  },
};
// per-node override wins over group + global:
nodes.add({ id: 9, label: 'Special', group: 'normal', color: '#9b59b6', shape: 'star', size: 30 });
```
Color a node by data value with a scale you compute yourself, then write the hex into
each node's `color` before adding — vis-network has no built-in colormap.

### How to size nodes by a metric
```javascript
const options = { nodes: { scaling: { min: 10, max: 60, label: { enabled: true, min: 12, max: 24 } } } };
nodes.add([{ id: 1, value: 5 }, { id: 2, value: 80 }]); // 'value' drives the scaler
```

### How to build a hierarchical / directed tree
```javascript
const network = new vis.Network(container, { nodes, edges }, {
  layout: { hierarchical: { direction: 'LR', sortMethod: 'directed', shakeTowards: 'roots' } },
  physics: { hierarchicalRepulsion: { nodeDistance: 140 } },
  edges: { arrows: 'to', smooth: { type: 'cubicBezier', forceDirection: 'horizontal' } },
});
```

### How to highlight a node's neighborhood on hover
```javascript
network.on('hoverNode', ({ node }) => {
  const connected = new Set([node, ...network.getConnectedNodes(node)]);
  nodes.forEach((n) => nodes.update({ id: n.id, opacity: connected.has(n.id) ? 1 : 0.2 }));
});
network.on('blurNode', () => nodes.forEach((n) => nodes.update({ id: n.id, opacity: 1 })));
```

### How to freeze layout after stabilization (performance)
```javascript
new vis.Network(container, data, {
  physics: { stabilization: { enabled: true, iterations: 300, fit: true } },
}).once('stabilizationIterationsDone', function () { this.setOptions({ physics: false }); });
```

### How to add an interactive editor (manipulation UI)
```javascript
const network = new vis.Network(container, { nodes, edges }, {
  manipulation: {
    enabled: true,                          // shows the edit toolbar
    addNode: (data, cb) => { data.label = prompt('Label?') || 'new'; cb(data); },
    addEdge: (data, cb) => { if (data.from !== data.to) cb(data); }, // block self-loops
    editNode: (data, cb) => { data.label = prompt('New label', data.label); cb(data); },
    deleteNode: true, deleteEdge: true,
  },
});
```

### How to cluster a large graph then expand on click
```javascript
network.clusterByHubsize(6);                             // collapse hubs (≥6 links)
network.on('doubleClick', (p) => {
  if (p.nodes[0] && network.isCluster(p.nodes[0])) network.openCluster(p.nodes[0]);
});
```

## Hierarchical Layout Reference
`layout.hierarchical` accepts: `enabled`, `direction` (`UD`/`DU`/`LR`/`RL`),
`sortMethod` (`hubsize` | `directed`), `levelSeparation` (px between ranks),
`nodeSpacing` (px within a rank), `treeSpacing` (px between disconnected trees),
`shakeTowards` (`roots` | `leaves`), `blockShifting`, `edgeMinimization`, and
`parentCentralization`. Pair with `physics.hierarchicalRepulsion.nodeDistance`. You can
also pin a node's rank explicitly with a per-node `level` field.

## Events Reference
Common events on `network.on(name, cb)`: `click`, `doubleClick`, `oncontext`,
`hold`, `select` / `deselectNode` / `deselectEdge`, `selectNode`, `selectEdge`,
`hoverNode` / `blurNode` (need `interaction.hover:true`), `dragStart` / `dragging` /
`dragEnd`, `zoom`, `showPopup` / `hidePopup`, `startStabilizing`,
`stabilizationProgress`, `stabilizationIterationsDone`, `stabilized`. Handlers receive a
`params` object with `nodes`, `edges`, `pointer`, and `event`.

## Do's and Don'ts

### ✅ Do
- Mutate data through the `DataSet` (`nodes.update(...)`), not by rebuilding the whole graph — it re-renders incrementally.
- Disable physics once stabilized for static graphs; it stops the CPU spinning.
- Use `groups` for repeated styling instead of copying color objects onto every node.
- Set `interaction.hover: true` before relying on `hoverNode`/`blurNode` events (hover is off by default).

### ❌ Don't
- Don't push >2–3k physics-enabled nodes; the barnesHut simulation stalls. Cluster, or pre-compute positions and set `physics:false`.
- Don't forget unique `id`s — duplicate ids silently overwrite in a DataSet.
- Don't set both `size` and expect it to apply to `box`/`ellipse` — those size to their label; `size` only affects `dot`/`image`/`icon`.
- Don't animate `smooth: { type: 'dynamic' }` on large graphs — it adds hidden support nodes and multiplies physics cost; use `continuous` or `false`.

## Styling, Theming & Customization
- **Fonts**: `font: { color, size, face, background, strokeWidth, strokeColor, multi: 'html' }` (`multi` enables bold/italic markup in labels).
- **Node color object**: `{ background, border, highlight: {background, border}, hover: {...} }`.
- **Edge color**: `{ color, highlight, hover, inherit: 'from'|'to'|'both'|false, opacity }`. `inherit` pulls color from endpoints — set `inherit:false` to use an explicit edge color.
- **Images/icons**: `shape:'image'` + `image: url`; or `shape:'icon'` + `icon: { face: 'FontAwesome', code: '', color }`.
- **Dark theme**: there is no theme switch — set dark defaults in `nodes`/`edges`/`font` and a dark container background via CSS.

## Advanced Features
- **Clustering**: `network.cluster`, `clusterByHubsize`, `clusterOutliers`, `openCluster` for level-of-detail on big graphs.
- **Manipulation UI**: `manipulation: { enabled: true, addNode, addEdge, editNode }` gives an interactive editor toolbar.
- **Export**: grab the canvas — `network.canvas.frame.canvas.toDataURL('image/png')` — vis-network has no native SVG export (it's canvas-only).
- **Coordinate conversion**: `network.canvasToDOM` / `DOMtoCanvas` for overlaying HTML on nodes.

## Common Pitfalls & Troubleshooting
- **Blank canvas**: the container must have an explicit height (canvas collapses to 0 otherwise).
- **Jittery/exploding layout**: lower `gravitationalConstant` magnitude or raise `springLength`; enable `stabilization`.
- **Tooltips not showing**: `title` renders as a DOM tooltip; pass a string or an `HTMLElement`, and ensure the vis-network CSS is loaded.
- **Canvas, not SVG**: you cannot select individual nodes with CSS/DOM tools — everything is drawn to one canvas. For SVG output use Cytoscape.js or D3 instead.

## Best For / Avoid For
`interactive-network`, `org-chart`, `dependency-graph`, `dag`, `small-medium-graphs`, `physics-layout` — choose vis-network when you want drag/zoom/physics out of the box.
Avoid for: very large graphs (>3k nodes — use `sigma_js`), SVG/vector export needs (use `cytoscape_js` or D3), or highly custom render pipelines.

## Performance & Limits
- **Physics is the bottleneck.** `barnesHut` is O(n log n) per tick but ticks run every frame during stabilization; interactive limit is roughly 1–2k nodes / 3–5k edges before the layout drags. Beyond that: pre-compute positions and set `physics:false`, or cluster.
- **Clustering for scale**: `network.clusterByHubsize()` or `clusterOutliers()` collapse dense regions into single cluster nodes; `openCluster(id)` expands on demand.
- **Stabilization cost**: `stabilization.iterations` trades startup time for a settled initial view; set `updateInterval` to render progress. `stabilization: false` starts animating immediately (looks livelier, converges on screen).
- **Canvas, single draw call**: rendering is cheap relative to physics; disabling physics makes even large static graphs smooth to pan/zoom.
- **Memory**: each DataSet row is a plain object; hundreds of thousands are fine to *hold*, the limit is *simulating* them.

```javascript
// scale pattern: layout once with a hierarchical/physics pass, then freeze
network.once('stabilizationIterationsDone', () => network.setOptions({ physics: false }));
network.clusterByHubsize(8); // collapse hubs with ≥8 connections
```

## Integration Notes
- **Frameworks**: vis-network is imperative — in React, create the `Network` in a `useEffect` bound to a `ref`, keep the `DataSet`s in a `useRef`, and `nodes.update(...)` on prop changes rather than re-`new`-ing the network. Destroy with `network.destroy()` on unmount. The community `react-graph-vis` wrapper exists but lags releases; the manual pattern is more reliable.
- **Streaming/live data**: subscribe to your source and call `nodes.add/update/remove` — the network re-renders the delta only. Keep physics off for high-frequency updates or the graph never settles.
- **SSR**: canvas rendering requires the DOM; guard against server rendering (`typeof window !== 'undefined'`) and instantiate client-side only.
- **vis-data reuse**: the same `DataSet` can back multiple views (e.g. a network plus a `vis-timeline`) — they stay in sync automatically.

## See Also
- `cytoscape_js.md` — SVG/canvas graph library with a rich algorithm + styling API.
- `sigma_js.md` — WebGL renderer for large graphs (10k+ nodes).
- `go_js.md` — commercial diagramming with templates and undo/redo.
- `cola_js.md` — constraint-based layout you can pair with a renderer.
- `../use-case/networks-graphs.md` — choosing among network/graph tools.
