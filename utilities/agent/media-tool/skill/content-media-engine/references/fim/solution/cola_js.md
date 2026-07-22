---
name: Cola.js (WebCola)
description: Constraint-based graph layout library with advanced positioning algorithms
docs: https://ialab.it.monash.edu/webcola/
examples: https://ialab.it.monash.edu/webcola/examples.html
---

# WebCola (cola.js) — constraint-based graph layout engine

WebCola is a **layout engine**, not a renderer. It computes node positions using
constraint-based force-directed layout (based on the "IPSep-CoLa" research) and hands the
coordinates to *you* to draw — almost always with D3/SVG. What sets it apart from plain
force layouts is first-class **constraints**: alignment, ordered separation, directional
flow for DAGs, non-overlap, and hierarchical **groups** (containers). You express the
shape you want ("these nodes align on Y", "sources flow left-to-right", "don't overlap")
and WebCola satisfies them while relaxing edge lengths. This file is the API reference; a
higher-level overview lives at `../overview/network-3d-graphics/cola_js.md`.

**Current Version**: webcola 3.4.x (current major)  **License**: MIT  **Runtime**: browser (or Node headless); layout only — pair with a renderer

## Official Resources & Documentation
- Site + examples: https://ialab.it.monash.edu/webcola/
- Examples index: https://ialab.it.monash.edu/webcola/examples.html
- GitHub: https://github.com/tgdwyer/WebCola
- npm: https://www.npmjs.com/package/webcola
- API notes: https://github.com/tgdwyer/WebCola/wiki

## Installation & Setup

### Package manager
```bash
npm install webcola
# typically alongside a renderer:
npm install d3
```

### CDN / browser
```html
<script src="https://cdn.jsdelivr.net/npm/d3@7/dist/d3.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/webcola@3.4.0/WebCola/cola.min.js"></script>
```

### Import styles (ESM)
```javascript
import * as cola from 'webcola';
```

## Core Syntax / API Reference

### Two entry points
- `cola.d3adaptor(d3)` — integrates with a D3 selection/tick loop (most common).
- `new cola.Layout()` — headless engine; drive it manually and read positions.

### The data model
Nodes are objects with `width`/`height` (used for overlap avoidance); the layout writes
`x`/`y` (center) onto them. Links reference nodes **by array index** or by object
reference, with an optional `length` (target edge length).
```javascript
const nodes = [
  { name: 'a', width: 60, height: 40 },
  { name: 'b', width: 60, height: 40 },
  { name: 'c', width: 60, height: 40 },
];
const links = [
  { source: 0, target: 1 },        // index refs
  { source: 1, target: 2 },
];
```

### Constraints
The distinguishing feature. Two primitive kinds plus alignment:
```javascript
const constraints = [
  // ordered separation: b must be at least 50px right of a on the x axis
  { axis: 'x', left: 0, right: 1, gap: 50 },
  // alignment: nodes 0 and 2 share the same y (horizontal alignment)
  { type: 'alignment', axis: 'y', offsets: [{ node: 0, offset: 0 }, { node: 2, offset: 0 }] },
];
```
`gap` separation constraints build grids, layers, and orderings; `alignment` constraints
pin nodes onto a shared axis line.

### Groups (hierarchical containment)
Groups draw bounding boxes around sets of nodes and can nest:
```javascript
const groups = [
  { leaves: [0, 1], padding: 10 },      // a box containing nodes 0 and 1
  { groups: [0], leaves: [2] },          // a group containing group 0 and node 2
];
```

### Configuring & running (d3adaptor)
```javascript
const d3cola = cola.d3adaptor(d3)
  .size([width, height])
  .nodes(nodes)
  .links(links)
  .constraints(constraints)
  .groups(groups)
  .linkDistance(100)          // base edge length
  .avoidOverlaps(true)        // treat width/height as hard non-overlap
  .handleDisconnected(true)   // pack disconnected components
  .flowLayout('y', 40)        // directed downward flow, min 40px between ranks
  .symmetricDiffLinkLengths(6)// auto edge lengths from graph structure
  .start(30, 20, 20);         // unconstrained, user-constraint, all-constraint iterations
```
`.start(a, b, c)` runs three annealing phases; more iterations = better constraint
satisfaction, slower. `.flowLayout(axis, minSep)` turns a general layout into a DAG layout.

### The tick loop (render integration)
```javascript
d3cola.on('tick', () => {
  link.attr('x1', d => d.source.x).attr('y1', d => d.source.y)
      .attr('x2', d => d.target.x).attr('y2', d => d.target.y);
  node.attr('transform', d => `translate(${d.x},${d.y})`);
});
d3cola.on('end', () => console.log('layout converged'));
```

## Supported Layout Behaviors
- **Constraint-based force layout** (general graphs with alignment/separation rules).
- **Directed / flow layout** for DAGs via `flowLayout`.
- **Non-overlapping** node layout via `avoidOverlaps`.
- **Grouped / hierarchical** layout via `groups` (nested containers).
- **Grid snapping / power graphs** via extension routines (`gridify`, power-graph modules).

## How-To (worked recipes)

### How to color and style nodes & edges
WebCola computes positions only — **styling is entirely your renderer's job** (SVG/CSS).
Bind colors and sizes in the D3 draw code, using the same node objects WebCola positions:
```javascript
const node = svg.selectAll('.node').data(nodes).enter().append('rect')
  .attr('class', 'node')
  .attr('width', d => d.width).attr('height', d => d.height)
  .attr('rx', 5)
  .style('fill', d => CATEGORY_COLORS[d.group] ?? '#4f8ef7')   // color by data
  .style('stroke', '#2c3e50')
  .call(d3cola.drag);                                          // make draggable

const link = svg.selectAll('.link').data(links).enter().append('line')
  .attr('class', 'link')
  .style('stroke', d => d.critical ? '#e74c3c' : '#bbbbbb')
  .style('stroke-width', d => 1 + (d.weight || 1));
// WebCola sets d.source.x/y each tick; your stroke/fill styling is independent.
```

### How to make a left-to-right DAG
```javascript
cola.d3adaptor(d3).size([w, h]).nodes(nodes).links(links)
   .flowLayout('x', 60)     // sources flow to the left, targets to the right
   .avoidOverlaps(true)
   .start(30, 30, 30);
```

### How to align nodes into a row
```javascript
const constraints = [{
  type: 'alignment', axis: 'y',
  offsets: nodes.map((_, i) => ({ node: i, offset: 0 })),
}];
```

### How to use WebCola inside Cytoscape.js
The `cytoscape-cola` extension wraps this engine so you get constraints without the D3
plumbing: `cy.layout({ name: 'cola', flow: { axis: 'y', minSeparation: 30 }, alignment, gap }).run();`
(see `cytoscape_js.md`).

### How to draw grouped containers
Groups produce `bounds` you render as background rectangles behind their members:
```javascript
const groups = [{ leaves: [0, 1], padding: 12 }, { leaves: [2, 3], padding: 12 }];
d3cola.groups(groups).start(30, 20, 20);

const group = svg.selectAll('.group').data(groups).enter().insert('rect', '.node')
  .attr('rx', 8).attr('ry', 8).style('fill', '#f0f4ff').style('stroke', '#aac');
d3cola.on('tick', () => {
  group.attr('x', d => d.bounds.x).attr('y', d => d.bounds.y)
       .attr('width', d => d.bounds.width()).attr('height', d => d.bounds.height());
  // ...position nodes/links as usual
});
```

### How to route edges orthogonally (gridify)
After the force pass settles, WebCola can snap to a routing grid for right-angle edges:
```javascript
d3cola.on('end', () => {
  const routes = d3cola.prepareEdgeRouting(margin); // then compute per-edge polyline routes
  link.attr('d', d => lineFromRoute(d3cola.routeEdge(d)));
});
```

## Configuration Reference
Adaptor/`Layout` chainable options: `.nodes()`, `.links()`, `.constraints()`, `.groups()`,
`.size([w,h])`, `.linkDistance(n | fn)`, `.symmetricDiffLinkLengths(ideal, w?)`,
`.jaccardLinkLengths(ideal, w?)`, `.avoidOverlaps(bool)`, `.handleDisconnected(bool)`,
`.flowLayout(axis, minSep)`, `.convergenceThreshold(n)`, `.defaultNodeSize(n)`. Events:
`.on('start'|'tick'|'end', cb)`. Run with `.start(unconstrainedIters, userConstraintIters,
allConstraintIters, gridSnapIters?)`.

## Do's and Don'ts

### ✅ Do
- Set realistic `width`/`height` on nodes when `avoidOverlaps` is on — the engine treats them as collision boxes.
- Use `flowLayout` for directed/hierarchical graphs instead of hand-built separation chains.
- Raise `.start()` iteration counts for hard constraint sets; lower them for interactive responsiveness.
- Reuse the node objects between WebCola and your renderer — WebCola mutates their `x`/`y` in place each tick.

### ❌ Don't
- Don't expect WebCola to draw anything — no styling, no DOM; wire it to D3/SVG (or use `cytoscape-cola`).
- Don't over-constrain — conflicting separation/alignment constraints prevent convergence; add them incrementally.
- Don't mix index-based and object-based `source`/`target` in the same links array — pick one.
- Don't forget the `tick` handler — without it the DOM never updates even though positions are computing.

## Styling, Theming & Customization
All visual theming is delegated to the rendering layer (D3/SVG/CSS), so:
- **Node color/shape/size**: SVG `fill`, `stroke`, `rx`, `<circle>` vs `<rect>` in your enter selection.
- **Edge color/width/dash**: SVG `stroke`, `stroke-width`, `stroke-dasharray`.
- **Group boxes**: draw a `<rect>` per group using the `bounds` WebCola computes (`group.bounds.x/y/width()/height()`).
- **Labels**: append `<text>` and update its transform in the tick handler.

## Advanced Features
- **Power graphs**: `powerGraphGroups` collapse dense subgraphs into module edges (reduces clutter).
- **Grid layout / `gridify`**: snap constrained layouts to a routing grid for orthogonal edges.
- **Overlap-free groups with padding**: nested containers with per-group `padding`.
- **Headless use**: `new cola.Layout()` in Node to precompute positions server-side, then ship coordinates to the client.

## Performance & Limits
- **Constraint solving is the cost.** Each `.start()` phase runs an iterative solver; complexity grows with node count and especially with the number of constraints. Practical smooth-interaction limit is a few hundred to ~1–2k nodes; beyond that, precompute layout once (fewer live ticks) or use a simpler force layout.
- **`avoidOverlaps` adds work**: non-overlap is a per-tick separation pass — disable it if node boxes are already sparse.
- **Iteration budget**: `.start(unconstrained, userConstraint, allConstraint)` — front-load unconstrained iterations for a good initial shape, then constraint iterations to satisfy rules. More = better but slower.
- **Headless precompute**: run `new cola.Layout()` (no d3) server-side or in a worker, read final `x`/`y`, and ship coordinates so the client skips the solve entirely.

## Integration Notes
- **cytoscape-cola**: the most common way to use WebCola in practice — Cytoscape.js wraps it as a layout (`name:'cola'`) with `flow`, `alignment`, and `gap` options, so you get constraints without hand-writing the D3 tick loop (see `cytoscape_js.md`).
- **D3 v4–v7**: `cola.d3adaptor(d3)` binds to a D3 instance; pass the whole `d3` module. The drag behavior is `d3cola.drag`.
- **React/SVG**: manage nodes/links in state, run the adaptor in an effect, and update SVG attrs in the `tick` handler; treat WebCola as the position source of truth.
- **Renderers**: any renderer works (raw SVG, canvas, Pixi) — WebCola only produces coordinates; `sigma_js`/`vis_js` have their own layouts so you'd only pair WebCola with a lower-level renderer.

## Common Pitfalls & Troubleshooting
- **Nodes overlap despite `avoidOverlaps`**: node `width`/`height` are missing or zero.
- **Layout won't settle**: constraint conflict, or too few `.start()` iterations — increase them or remove a constraint.
- **Nothing moves on screen**: missing `tick` handler, or you're reading `d.x` before `start()` runs.
- **Edges point to wrong nodes**: index vs object `source`/`target` mismatch after filtering the nodes array (indices shift).
- **Sparse docs**: the examples page is the best reference; the API is small but under-documented.

## Best For / Avoid For
`constraint-layout`, `uml-diagrams`, `dag`, `hierarchical-network`, `aligned-layout`, `overlap-free`, `d3-integration` — choose WebCola when you need *structured* layout (alignment, flow, grouping), not just a blob of force-directed nodes.
Avoid for: turnkey rendering (use `vis_js`/`cytoscape_js`), very large graphs (constraint solving is costly), or when a plain force layout suffices (use `d3-force` / `springy_js`).

## See Also
- `../overview/network-3d-graphics/cola_js.md` — higher-level overview of WebCola.
- `cytoscape_js.md` — pairs with WebCola via the `cytoscape-cola` layout extension.
- `springy_js.md` — a far simpler, unconstrained force layout.
- `sigma_js.md` / `vis_js.md` — renderers you could feed WebCola positions into.
- `../use-case/networks-graphs.md` — choosing among network/graph tools.
