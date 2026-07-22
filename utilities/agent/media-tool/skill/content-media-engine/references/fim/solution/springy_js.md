---
name: Springy.js
description: Lightweight force-directed graph layout library with spring physics simulation
docs: http://getspringy.com/
examples: http://getspringy.com/#demo
---

# Springy.js — tiny force-directed graph layout + canvas renderer

Springy.js is a minimal (~8KB) force-directed graph layout library. It models edges as
springs and nodes as mutually-repelling charges, integrates the physics, and gives you
node/edge positions to draw — with an optional canvas renderer and a jQuery plugin that
does the drawing for you. It is deliberately tiny and dependency-free: no algorithms, no
constraints, no WebGL, no styling system. Reach for it when you want a small animated
graph in a few lines and don't need scale or features. It is old and lightly maintained,
but stable and still perfectly usable for small diagrams.

**Current Version**: springy 2.8.x (current; low-churn)  **License**: MIT  **Runtime**: browser canvas; suited to small graphs (tens of nodes)

## Official Resources & Documentation
- Site + demo: http://getspringy.com/
- GitHub: https://github.com/dhotson/springy
- npm: https://www.npmjs.com/package/springy

## Installation & Setup

### Package manager
```bash
npm install springy
```

### Browser (script tags)
```html
<script src="springy.js"></script>
<script src="springyui.js"></script>  <!-- optional: jQuery canvas renderer -->
```
`springy.js` is the physics + graph model; `springyui.js` is the jQuery plugin renderer.

## Core Syntax / API Reference

### Building a graph
```javascript
const graph = new Springy.Graph();

// nodes carry an arbitrary data object (label/color/font are conventions the renderer reads)
const a = graph.newNode({ label: 'Alpha', color: '#4f8ef7' });
const b = graph.newNode({ label: 'Beta',  color: '#e0607e' });
const c = graph.newNode({ label: 'Gamma' });

// edges connect two node objects, with optional data
graph.newEdge(a, b, { color: '#999', label: 'links' });
graph.newEdge(b, c, { color: '#999' });
```
Bulk-load helper:
```javascript
graph.loadJSON({
  nodes: ['a', 'b', 'c'],
  edges: [['a', 'b'], ['b', 'c']],
});
```

### The layout (force simulation)
```javascript
const layout = new Springy.Layout.ForceDirected(
  graph,
  400.0,   // stiffness  — spring constant (higher = tighter edges)
  400.0,   // repulsion  — node-node repulsion (higher = more spread)
  0.5,     // damping    — velocity decay (0–1; higher settles faster)
  0.00001  // minEnergyThreshold — stop when kinetic energy drops below this (optional)
);
```
These four numbers are essentially the entire tuning surface.

### The renderer
Springy's `Renderer` calls your draw callbacks each animation frame; you own the canvas
drawing. Node/edge positions come from the layout.
```javascript
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');

const renderer = new Springy.Renderer(
  layout,
  () => { ctx.clearRect(0, 0, canvas.width, canvas.height); },       // clear frame
  (edge, p1, p2) => {                                                // draw one edge
    ctx.strokeStyle = edge.data.color || '#999';
    ctx.beginPath(); ctx.moveTo(p1.x * 50 + 300, p1.y * 50 + 200);
    ctx.lineTo(p2.x * 50 + 300, p2.y * 50 + 200); ctx.stroke();
  },
  (node, p) => {                                                     // draw one node
    ctx.fillStyle = node.data.color || '#4f8ef7';
    ctx.beginPath(); ctx.arc(p.x * 50 + 300, p.y * 50 + 200, 8, 0, 2 * Math.PI); ctx.fill();
  }
);
renderer.start();
```
Layout coordinates are in abstract units centered near the origin — scale/translate them
into pixel space in your callbacks (the `* 50 + 300` above).

### The jQuery renderer (batteries-included)
```javascript
jQuery(function () {
  jQuery('#canvas').springy({ graph: graph, nodeSelected: (node) => console.log(node.data) });
});
```
This uses `springyui.js` to draw labels, edges, and handle basic interaction for you.

## Supported Output
- Animated force-directed node-link graph on a 2D canvas.
- Custom drawing via renderer callbacks (any canvas shapes/labels you write).
- Turnkey drawing + labels + selection via the `springyui.js` jQuery plugin.

## How-To (worked recipes)

### How to color and style nodes & edges
Springy has no styling system — you stash style hints in each node/edge `data` object and
read them in your renderer callbacks (or the jQuery plugin reads `label`/`color`).
```javascript
const hub  = graph.newNode({ label: 'Hub',  color: '#e74c3c', radius: 14 });
const leaf = graph.newNode({ label: 'Leaf', color: '#2ecc71', radius: 7 });
graph.newEdge(hub, leaf, { color: '#f39c12', width: 3 });

// in the node draw callback, honor those hints:
(node, p) => {
  ctx.fillStyle = node.data.color || '#4f8ef7';
  ctx.beginPath();
  ctx.arc(toX(p.x), toY(p.y), node.data.radius || 8, 0, 2 * Math.PI);
  ctx.fill();
}
```

### How to tune the layout spread
```javascript
// tighter clusters: high stiffness, low repulsion
new Springy.Layout.ForceDirected(graph, 600, 200, 0.5);
// airy spread: low stiffness, high repulsion
new Springy.Layout.ForceDirected(graph, 200, 800, 0.4);
```

### How to add nodes/edges at runtime
```javascript
const d = graph.newNode({ label: 'Delta' });
graph.newEdge(a, d);   // renderer picks it up on the next frame automatically
```

### How to react to node clicks (jQuery plugin)
```javascript
jQuery('#canvas').springy({ graph, nodeSelected: (node) => showDetails(node.data) });
```

## Do's and Don'ts

### ✅ Do
- Keep graphs small (tens of nodes) — Springy's O(n²) repulsion doesn't scale.
- Store style hints in `node.data` / `edge.data` and read them in your callbacks.
- Scale/offset layout coordinates into pixel space inside the draw callbacks.
- Use `springyui.js` when you just want a quick labeled graph without writing canvas code.

### ❌ Don't
- Don't use Springy for hundreds+ of nodes or for analysis — use `sigma_js` (scale) or `networkx`/`igraph` (analysis).
- Don't expect built-in labels/arrows/styling in the core — that lives in `springyui.js` or your callbacks.
- Don't forget it depends on jQuery *only* for the `springyui.js` renderer; the core layout is dependency-free.
- Don't rely on precise/stable positions — it's a live simulation; positions drift until energy settles.

## Styling, Theming & Customization
- **All visuals are yours**: color, radius, edge width, dashes, labels are whatever you draw in the renderer callbacks from `data` fields.
- **jQuery renderer conventions**: it reads `node.data.label`, `node.data.color`, and `node.data.font` to draw text and fills.
- **Coordinate mapping**: layout units are abstract; define `toX`/`toY` helpers to place and zoom the graph.
- **No theme system**: implement light/dark by branching colors in your callbacks.

## Advanced Features
- Springy is intentionally feature-light. The extent of "advanced" is: custom renderer
  callbacks, `loadJSON` bulk loading, runtime add/remove of nodes and edges, and the
  `minEnergyThreshold` early-stop. There is no clustering, no constraints, no export, no
  algorithm library — by design.

## Complete runnable example
A full self-contained page using the jQuery renderer (the fastest way to a working graph):
```html
<!DOCTYPE html>
<html>
<head>
  <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/springy@2.8.0/springy.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/springy@2.8.0/springyui.js"></script>
</head>
<body>
  <canvas id="graph" width="640" height="480"></canvas>
  <script>
    const graph = new Springy.Graph();
    graph.loadJSON({
      nodes: ['Alpha', 'Beta', 'Gamma', 'Delta'],
      edges: [['Alpha', 'Beta'], ['Beta', 'Gamma'], ['Gamma', 'Delta'], ['Delta', 'Alpha']],
    });
    jQuery(function () {
      jQuery('#graph').springy({
        graph: graph,
        nodeSelected: (node) => console.log('selected', node.data),
      });
    });
  </script>
</body>
</html>
```

## Performance & Limits
- **O(n²) repulsion, no spatial index** — every node repels every other each tick. Comfortable up to a few dozen nodes; noticeably sluggish past ~100.
- **Live simulation**: it keeps integrating until kinetic energy falls below `minEnergyThreshold`; without one it animates indefinitely (gentle drift). Set the threshold to stop cleanly.
- **Canvas redraw** each frame is cheap; the physics loop is the cost. There is no clustering or level-of-detail — it's not built for scale.
- **Tuning trade-off**: higher `damping` settles faster but can freeze before spreading; balance against `repulsion`.

## Integration Notes
- **jQuery dependency is renderer-only**: `springyui.js` needs jQuery; the core `springy.js` (graph + layout) has zero dependencies and can drive a hand-written canvas/SVG renderer.
- **Frameworks**: in React/Vue, run the core layout and read `layout.eachNode((node, point) => point.p.x/y)` inside your own render loop bound to a `ref`ed canvas; skip `springyui.js`.
- **Data**: `graph.loadJSON({nodes, edges})` is the quickest bulk load; `graph.newNode/newEdge` for incremental building.
- **No export**: snapshot the canvas yourself with `canvas.toDataURL('image/png')` — Springy has no export API.

## Common Pitfalls & Troubleshooting
- **Graph drawn off-screen / tiny**: you didn't scale+translate layout coordinates into canvas pixels.
- **Nodes fly apart or collapse**: repulsion/stiffness are mismatched — rebalance the two, raise damping.
- **Never settles**: set a `minEnergyThreshold`, or accept perpetual gentle motion (it's a live sim).
- **No labels**: you're using core `springy.js` without `springyui.js` and didn't draw text yourself.
- **jQuery not defined**: `springyui.js` requires jQuery on the page; the core does not.

## Best For / Avoid For
`lightweight-graph`, `educational`, `small-network`, `embedded-widget`, `quick-demo`, `zero-dependency-core` — choose Springy when tiny size and simplicity beat features.
Avoid for: large graphs (use `sigma_js`), constrained/structured layout (use `cola_js`), rich interactive diagrams (use `vis_js`/`cytoscape_js`/`go_js`), or any network analysis (use `networkx`/`igraph`).

## See Also
- `vis_js.md` — a fuller interactive network library with physics built in.
- `cola_js.md` — constraint-based layout when you need structure, not just springs.
- `sigma_js.md` — when the graph outgrows a canvas force sim.
- `cytoscape_js.md` — full-featured graph library with styling + algorithms.
- `../use-case/networks-graphs.md` — choosing among network/graph tools.
