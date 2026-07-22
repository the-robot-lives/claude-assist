---
name: yFiles for HTML
description: Professional commercial graph visualization library with automatic layouts
docs: https://www.yworks.com/products/yfiles-for-html
examples: https://www.yworks.com/demos/
---

# yFiles for HTML — commercial graph library with best-in-class automatic layout

yFiles for HTML (by yWorks) is the premium commercial graph/diagram library. Its
distinguishing strength is the automatic **layout** library — hierarchical, orthogonal,
organic, tree, radial, and circular algorithms that are the most mature in the industry —
plus high-performance rendering (SVG + WebGL2), a rich interaction/editing framework,
and data-binding builders. It targets enterprise diagramming: network management, BPMN,
data lineage, CAD-like schematics, and knowledge graphs. It requires a paid developer
license; the npm package and API are only usable with a license key. Because the API is
large and versions rename classes, prefer describing capabilities and lean on the docs
for exact current class names.

**Current Version**: yFiles for HTML 3.x (current major)  **License**: commercial (per-developer, paid)  **Runtime**: browser SVG + WebGL2; scales to 10k+ elements with the WebGL renderer

## Official Resources & Documentation
- Product: https://www.yworks.com/products/yfiles-for-html
- Developer's Guide + API: https://docs.yworks.com/yfileshtml/
- Live demos: https://www.yworks.com/demos/
- npm (license-gated): https://www.npmjs.com/package/yfiles

> Version note: yFiles 3.x reorganized/renamed several classes vs 2.x (for example some
> layout classes moved from `Hierarchic*` toward `Hierarchical*` naming). Confirm exact
> identifiers against the version of the Developer's Guide you're targeting — this doc
> describes the stable *capabilities*, not a frozen class list.

## Installation & Setup
```bash
# obtain a license + the packaged module from yWorks, then:
npm install ./path-to/yfiles.tgz     # or the registered package under your license
```
Licensing is mandatory before any component renders:
```javascript
import { License } from 'yfiles';
License.value = { /* your JSON license object from yWorks */ };
```

### Import styles (ESM)
```javascript
import { GraphComponent, GraphEditorInputMode, ShapeNodeStyle } from 'yfiles';
```

## Core Syntax / API Reference

### The view: GraphComponent
The `GraphComponent` binds a graph to a DOM element and owns the viewport, rendering, and
input handling.
```javascript
const graphComponent = new GraphComponent('#graphComponent');
graphComponent.inputMode = new GraphEditorInputMode();   // interactive editing
// GraphViewerInputMode for read-only pan/zoom/tooltips
const graph = graphComponent.graph;                      // the IGraph model
```

### Building the graph (IGraph)
```javascript
const n1 = graph.createNode({
  layout: [100, 100, 40, 40],                            // x, y, w, h
  style: new ShapeNodeStyle({ shape: 'ellipse', fill: '#4f8ef7', stroke: '#2c3e50' }),
  tag: { id: 'server-1', kind: 'server' },               // your domain data on .tag
});
const n2 = graph.createNode({ layout: [260, 160, 40, 40],
  style: new ShapeNodeStyle({ shape: 'round-rectangle', fill: '#e0607e' }) });

const edge = graph.createEdge(n1, n2);
graph.addLabel(n1, 'Server');                            // labels are first-class objects
graph.addLabel(edge, 'connects');
```
`tag` is the standard place to attach your application data to any node/edge/label.

### Styles
Nodes: `ShapeNodeStyle`, `RectangleNodeStyle`, `ImageNodeStyle`, `GroupNodeStyle`, plus
template/SVG-based styles for full custom visuals. Edges: `PolylineEdgeStyle`,
`ArcEdgeStyle`, `BezierEdgeStyle`. Labels: `LabelStyle` (text/background/typography).
Ports: `ShapePortStyle`. Set defaults so new items inherit them:
```javascript
graph.nodeDefaults.style = new ShapeNodeStyle({ shape: 'round-rectangle', fill: '#eef' });
graph.edgeDefaults.style = new PolylineEdgeStyle({ stroke: '2px #888', targetArrow: 'triangle' });
```

### Automatic layout (the headline feature)
```javascript
import { HierarchicalLayout } from 'yfiles';   // (2.x: HierarchicLayout)
const layout = new HierarchicalLayout({ layoutOrientation: 'top-to-bottom' });
await graphComponent.applyLayoutAnimated(layout, '1s');   // animated morph to new positions
// non-animated: graphComponent.graph.applyLayout(layout)
```

### Data binding builders
Instead of `createNode` per item, bind arrays with a builder:
```javascript
import { GraphBuilder } from 'yfiles';
const builder = new GraphBuilder(graph);
const nodesSource = builder.createNodesSource({ data: myNodes, id: (n) => n.id });
builder.createEdgesSource({ data: myEdges, sourceId: (e) => e.from, targetId: (e) => e.to });
builder.buildGraph();
```
Also `TreeBuilder` (hierarchies) and `AdjacencyGraphBuilder` (adjacency-list data).

## Layout Algorithms
- **HierarchicalLayout** — layered DAGs, flowcharts, data lineage (the flagship).
- **OrganicLayout** — force-directed organic placement for general/large graphs.
- **OrthogonalLayout** — right-angle routing for schematics/UML/circuits.
- **TreeLayout / RadialTreeLayout (BalloonLayout)** — trees and mind maps.
- **RadialLayout** — concentric rings around roots.
- **CircularLayout** — cyclic/ring structures and clustered circles.
- Plus edge-routing algorithms (orthogonal, organic, polyline) that route edges without moving nodes.

## How-To (worked recipes)

### How to color and style nodes & edges
Assign a style object per item, or set graph-wide defaults, and re-style from data via the `tag`.
```javascript
const kindStyle = (kind) => new ShapeNodeStyle({
  shape: kind === 'db' ? 'round-rectangle' : 'ellipse',
  fill: { db: '#e74c3c', server: '#4f8ef7', cache: '#2ecc71' }[kind] ?? '#bdc3c7',
  stroke: '1.5px #2c3e50',
});
graph.nodes.forEach((node) => graph.setStyle(node, kindStyle(node.tag.kind)));

graph.edges.forEach((edge) =>
  graph.setStyle(edge, new PolylineEdgeStyle({
    stroke: edge.tag?.critical ? '3px #e74c3c' : '1.5px #999',
    targetArrow: 'triangle',
  })));
```

### How to apply a hierarchical layout with animation
```javascript
const layout = new HierarchicalLayout({ layoutOrientation: 'left-to-right' });
await graphComponent.applyLayoutAnimated(layout, '0.8s');
graphComponent.fitGraphBounds();
```

### How to enable interactive editing vs read-only viewing
```javascript
graphComponent.inputMode = new GraphEditorInputMode();  // create/delete/move/relabel
// or:
graphComponent.inputMode = new GraphViewerInputMode();  // pan/zoom/select/tooltip only
```

### How to switch to the WebGL renderer for large graphs
For 10k+ elements, use the WebGL2 rendering path (WebGL styles + `WebGLGraphModelManager`
per the current Developer's Guide) instead of SVG styles to keep interaction smooth.

## Style & Label Reference
- **Node styles**: `ShapeNodeStyle` (`shape`: `ellipse`, `rectangle`, `round-rectangle`,
  `triangle`, `diamond`, `hexagon`, `octagon`, `pill`; `fill`, `stroke`), `RectangleNodeStyle`,
  `ImageNodeStyle`, `GroupNodeStyle`, and template/SVG styles for custom visuals.
- **Edge styles**: `PolylineEdgeStyle` (`stroke`, `sourceArrow`, `targetArrow`),
  `ArcEdgeStyle`, `BezierEdgeStyle`; arrow presets like `'triangle'`, `'default'`, `'diamond'`.
- **Labels**: `LabelStyle` (text, `backgroundFill`, `textFill`, font); placement via
  label model parameters (`ExteriorNodeLabelModel`, `EdgeSegmentLabelModel`).
- **Ports**: `ShapePortStyle`; ports define where edges attach and enable orthogonal routing.
- **Decorators**: selection/highlight/focus visuals are customized through the graph's
  `decorator`, independent of the item's own style.

## Layout Configuration
Each layout takes a config object, e.g. `HierarchicalLayout({ layoutOrientation:
'top-to-bottom' | 'left-to-right' | 'bottom-to-top' | 'right-to-left', minimumLayerDistance,
nodeToNodeDistance })`; `OrganicLayout({ defaultPreferredEdgeLength, compactnessFactor,
minimumNodeDistance })`; `OrthogonalLayout({ gridSpacing })`; `TreeLayout` / `RadialTreeLayout`
for trees; `CircularLayout` for rings. Layout data (`HierarchicalLayoutData`, etc.) attaches
per-item constraints — layer assignment, grouping, port candidates, sequence — without
subclassing the algorithm. Apply with `graph.applyLayout(layout, layoutData)` or the
animated `graphComponent.applyLayoutAnimated(...)`.

## Do's and Don'ts

### ✅ Do
- Set `License.value` before constructing components — nothing renders without it.
- Attach domain data to `tag` and derive styles/layout from it, rather than hard-coding visuals.
- Use `GraphBuilder`/`TreeBuilder` for data-driven graphs instead of per-item `createNode`.
- Use the automatic layout library — it's the reason to pay for yFiles; don't hand-place nodes.

### ❌ Don't
- Don't use yFiles for open-source/unlicensed projects — it's commercial and license-gated (use `cytoscape_js`/`vis_js`).
- Don't copy class names blindly across major versions — 2.x↔3.x renamed layout/style classes; verify against your version's docs.
- Don't render 10k+ elements with SVG styles — switch to the WebGL2 renderer.
- Don't mutate the graph outside yFiles' model APIs — use `graph.createNode/createEdge/setStyle` so the view and undo engine stay consistent.

## Styling, Theming & Customization
- **Style objects per element type** (node/edge/label/port), each with rich properties (shape, fill, stroke, arrows, corner radius, typography).
- **Template & SVG styles** for fully custom node visuals bound to `tag` data.
- **Themes**: the demos ship light/dark theming; style defaults + CSS variables drive the look. Selection/highlight/focus have their own decorators.
- **Group nodes & folding**: collapsible containers with dedicated group styles.

## Advanced Features
- **Graph analysis**: shortest paths, centrality, clustering, reachability, cycles (the `algorithms` module).
- **Folding**: collapse/expand group hierarchies with automatic re-layout.
- **Edge routing** independent of layout (route edges around obstacles without moving nodes).
- **Export**: SVG, PNG, and PDF export utilities; printing across tiles.
- **Overview** component (mini-map), snap lines, orthogonal edge editing, and undo/redo out of the box.

### How to run graph analysis
```javascript
import { ShortestPath, BetweennessCentrality } from 'yfiles'; // algorithms module
const result = new ShortestPath({ source: n1, sink: n2, directed: true }).run(graph);
result.edges.forEach((e) => graph.setStyle(e, highlightStyle));
// centralities return per-node values you can map to size/color
```

### How to collapse groups (folding)
```javascript
// wrap the graph in a folding view; group nodes become collapsible
const foldingManager = new FoldingManager(graph);
const foldingView = foldingManager.createFoldingView();
graphComponent.graph = foldingView.graph;   // collapsing a group auto-re-routes edges
```

### How to export to PNG/SVG
```javascript
import { SvgExport } from 'yfiles';
const svg = await new SvgExport({ worldBounds: graphComponent.contentRect }).exportSvgAsync(graphComponent);
// PNG via a canvas render of the SVG, or the ImageExport helper in the demos
```

## Performance & Limits
- **Two render paths**: SVG (default, richest styling, best to ~1–2k elements) and **WebGL2** (for 10k–100k+ elements, simpler styles, far faster interaction). Choose per graph size.
- **Layout quality vs cost**: `HierarchicalLayout` and `OrthogonalLayout` are the most compute-heavy (they optimize crossings/bends); `OrganicLayout` has fast modes for large graphs; tree/circular are cheap.
- **Incremental layout**: yFiles supports incremental/constraint layout so adding a node doesn't reshuffle the whole diagram — important for large, evolving graphs.
- **Virtualization**: the view renders only what's visible; combined with WebGL this keeps very large graphs interactive.

## Integration Notes
- **Frameworks**: yWorks ships integration tutorials + demos for React, Angular, and Vue (component wrappers around `GraphComponent`). The library is framework-agnostic TypeScript; you mount it into a DOM element the framework owns.
- **Data binding**: `GraphBuilder`/`TreeBuilder`/`AdjacencyGraphBuilder` bind live data arrays and support incremental updates (`updateGraph()`), so a data change re-syncs nodes/edges without a full rebuild.
- **TypeScript**: fully typed; the package includes `.d.ts` and the API is designed type-first.
- **Bundling**: yFiles is large — use the yWorks-provided optimizer/tree-shaking guidance to ship only the modules you use; layout and view are separable.

## Common Pitfalls & Troubleshooting
- **Blank component / license error**: `License.value` not set, or the key doesn't match the package version.
- **`X is not exported`**: class renamed between major versions — check the current API reference.
- **Sluggish on large graphs**: you're on SVG styles — move to the WebGL2 renderer.
- **Layout ignores your positions**: automatic layouts reposition everything; use edge-routing-only algorithms or layout constraints if you must preserve positions.
- **npm install fails**: yFiles isn't on the public registry for unlicensed users — you install the packaged module provided with your license.

## Best For / Avoid For
`enterprise-diagramming`, `automatic-layout`, `data-lineage`, `network-management`, `bpmn`, `orthogonal-schematics`, `large-graphs`, `commercial-support` — choose yFiles when layout quality, scale, and vendor support justify the license cost.
Avoid for: budget/open-source projects (use `cytoscape_js`, `vis_js`, `sigma_js`), simple static graphs, or analysis-only pipelines (use `networkx`/`igraph`).

## See Also
- `go_js.md` — the other major commercial diagramming library (templates + undo/redo).
- `cytoscape_js.md` — the strongest open-source alternative (algorithms + styling).
- `cola_js.md` — open-source constraint-based layout if you only need layout.
- `sigma_js.md` — open-source WebGL rendering for large graphs.
- `../use-case/networks-graphs.md` — choosing among network/graph tools.
