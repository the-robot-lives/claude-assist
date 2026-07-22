---
name: GoJS
description: Feature-rich commercial diagramming library for interactive flowcharts and graphs
docs: https://gojs.net/latest/
examples: https://gojs.net/latest/samples/
---

# GoJS — commercial diagramming with templates, models, and layouts

GoJS builds interactive diagrams — flowcharts, org charts, BPMN, state machines, trees,
and general graphs — in the browser on an HTML5 canvas. Its defining idea is
**data-bound templates**: you declare a `Node`/`Link` template out of visual building
blocks, bind their properties to a plain-JS **model**, and GoJS renders and keeps them in
sync. It ships undo/redo, an interactive editing framework, and a large automatic-layout
library. It is commercial (paid license for production), though evaluation is unrestricted.

**Current Version**: GoJS 3.x (current major)  **License**: proprietary, per-developer (free to evaluate)  **Runtime**: browser canvas; handles thousands of parts, virtualization for more

## Official Resources & Documentation
- Docs/intro: https://gojs.net/latest/intro/
- API reference: https://gojs.net/latest/api/
- Samples: https://gojs.net/latest/samples/
- npm: https://www.npmjs.com/package/gojs
- GitHub (samples/extensions): https://github.com/NorthwoodsSoftware/GoJS

## Installation & Setup

### Package manager
```bash
npm install gojs
```

### CDN / browser
```html
<script src="https://cdn.jsdelivr.net/npm/gojs@3/release/go.js"></script>
```

### Import styles (ESM)
```javascript
import * as go from 'gojs';
```
The idiomatic constructor helper is `go.GraphObject.make`, conventionally aliased `$`.
GoJS 3 also supports plain builder syntax (`new go.Diagram(...)`); the `$` form remains
the most common in docs and samples.

## Core Syntax / API Reference

### Diagram, templates, model — the three pillars
```javascript
const $ = go.GraphObject.make;

// 1) Diagram: bound to a div, configured with a layout
const diagram = $(go.Diagram, 'myDiagramDiv', {
  'undoManager.isEnabled': true,
  layout: $(go.TreeLayout, { angle: 90, layerSpacing: 35 }),
});

// 2) Node template: a Panel of visual elements with data Bindings
diagram.nodeTemplate =
  $(go.Node, 'Auto',
    $(go.Shape, 'RoundedRectangle', { strokeWidth: 0 },
      new go.Binding('fill', 'color')),              // shape fill ← data.color
    $(go.TextBlock, { margin: 8, font: 'bold 14px sans-serif' },
      new go.Binding('text', 'name')));              // label ← data.name

// 3) Model: plain arrays of node + link data
diagram.model = new go.GraphLinksModel(
  [ { key: 1, name: 'Alpha', color: '#4f8ef7' },
    { key: 2, name: 'Beta',  color: '#e0607e' } ],
  [ { from: 1, to: 2 } ]);
```

### Panels — how visuals are composed
A `Node`/`Part` is a `Panel` containing `GraphObject`s. The panel **type** controls layout:
- `'Auto'` — a background shape sized to fit its content (the classic "shape wraps text").
- `'Vertical'` / `'Horizontal'` — stack children.
- `'Spot'` — position children by alignment spots (for badges, ports).
- `'Table'` — rows/columns.
- `'Position'` — absolute coordinates.

Building blocks: `go.Shape` (geometry: `'Rectangle'`, `'RoundedRectangle'`, `'Ellipse'`,
`'Diamond'`, `'Circle'`, custom geometry), `go.TextBlock`, `go.Picture` (images),
`go.Panel`, and `go.Placeholder` (for groups).

### Bindings
```javascript
new go.Binding('text', 'name')                        // one-way: data → object
new go.Binding('text', 'name').makeTwoWay()           // edits flow back to model
new go.Binding('fill', 'level', (lvl) => PALETTE[lvl]) // with a converter function
new go.Binding('location', 'loc', go.Point.parse).makeTwoWay(go.Point.stringify)
```
Always change data through the model in a transaction so undo works:
`diagram.model.setDataProperty(nodeData, 'color', '#f00')` inside
`diagram.commit((d) => { ... }, 'recolor')`.

### Link template
```javascript
diagram.linkTemplate =
  $(go.Link,
    { routing: go.Link.Orthogonal, corner: 6, relinkableFrom: true, relinkableTo: true },
    $(go.Shape, { strokeWidth: 2, stroke: '#555' }),          // the line
    $(go.Shape, { toArrow: 'Standard', fill: '#555', stroke: null }), // arrowhead
    $(go.TextBlock, new go.Binding('text', 'label'), { segmentOffset: new go.Point(0, -10) }));
```
Routing options: `go.Link.Normal`, `Orthogonal`, `AvoidsNodes`, `Bezier`.

### Models
- `go.GraphLinksModel` — general graphs; separate `nodeDataArray` + `linkDataArray`.
- `go.TreeModel` — trees; each node data has a `parent` key (no link array).
- `go.Model` — nodes only, no links.
Set `linkKeyProperty` when links need stable keys (for editing/persistence).
Serialize with `model.toJson()` / `go.Model.fromJson(text)`.

## Diagram / Layout Types
- **TreeLayout** — hierarchies, org charts, mind maps (`angle`, `layerSpacing`, `alignment`).
- **LayeredDigraphLayout** — layered DAGs / flowcharts (Sugiyama-style).
- **ForceDirectedLayout** — organic general graphs.
- **CircularLayout** — nodes on a ring.
- **GridLayout** — palettes and grids.
Sample-driven diagram kinds: flowcharts, BPMN, org charts, genogram/family trees, state
charts, sankey, swimlanes, mind maps, entity-relationship.

## How-To (worked recipes)

### How to color and style nodes & links
Bind visual properties to data, or set them statically on the template.
```javascript
diagram.nodeTemplate =
  $(go.Node, 'Auto',
    $(go.Shape, 'RoundedRectangle',
      { strokeWidth: 1.5, stroke: '#2c3e50' },
      new go.Binding('fill', 'category', (c) => ({ risk: '#e74c3c', ok: '#2ecc71' }[c] ?? '#bdc3c7'))),
    $(go.TextBlock, { margin: 6, stroke: '#fff' }, new go.Binding('text', 'name')));

// live recolor through a transaction (keeps undo working):
diagram.commit((d) => d.model.setDataProperty(nodeData, 'category', 'risk'), 'flag risk');
```

### How to render a tree / org chart
```javascript
const diagram = $(go.Diagram, 'div', { layout: $(go.TreeLayout, { angle: 90, layerSpacing: 40 }) });
diagram.model = new go.TreeModel([
  { key: 'CEO', name: 'CEO' },
  { key: 'CTO', parent: 'CEO', name: 'CTO' },
  { key: 'ENG', parent: 'CTO', name: 'Eng Lead' },
]);
```

### How to add ports and highlight on hover
```javascript
$(go.Shape, 'Circle',
  { portId: 'in', fromLinkable: false, toLinkable: true, cursor: 'pointer',
    mouseEnter: (e, obj) => obj.fill = '#f39c12',
    mouseLeave: (e, obj) => obj.fill = '#fff' });
```

### How to enable an interactive editor palette
```javascript
const palette = $(go.Palette, 'paletteDiv', { nodeTemplateMap: diagram.nodeTemplateMap });
palette.model = new go.GraphLinksModel([{ name: 'Task', color: '#4f8ef7' }, { name: 'Gate', color: '#e0607e' }]);
// drag from palette into diagram; undoManager already tracks the drop
```

### How to define ports for precise link endpoints
```javascript
diagram.nodeTemplate =
  $(go.Node, 'Spot',
    $(go.Shape, 'Rectangle', { fill: '#eef', width: 80, height: 40 }),
    $(go.TextBlock, new go.Binding('text', 'name')),
    // named ports at spots — links attach here via fromPort/toPort in link data
    $(go.Shape, 'Circle', { portId: 'in',  alignment: go.Spot.Left,  width: 8, height: 8, toLinkable: true }),
    $(go.Shape, 'Circle', { portId: 'out', alignment: go.Spot.Right, width: 8, height: 8, fromLinkable: true }));
// link data: { from: 1, fromPort: 'out', to: 2, toPort: 'in' }
// enable with new GraphLinksModel({ linkFromPortIdProperty: 'fromPort', linkToPortIdProperty: 'toPort' })
```

### How to export the diagram as an image
```javascript
const img = diagram.makeImageData({ scale: 2, background: 'white', type: 'image/png' });
// img is a data: URL — set as <img src> or trigger a download
const svg = diagram.makeSvg({ scale: 1, background: 'white' }); // vector export → SVGElement
```

## Model & Template Selection
- **TreeModel** — strict hierarchies (each node data has one `parent`); no link data array; pairs with `TreeLayout`.
- **GraphLinksModel** — general graphs, multiple/labeled links, ports; separate `nodeDataArray` + `linkDataArray`.
- **templateMap** — register multiple templates and switch per node with a `category` field: `diagram.nodeTemplateMap.add('start', startTemplate)` and set `data.category='start'`. This is how BPMN/flowchart samples give each shape type its own look. `go.Group` templates (with a `Placeholder`) build swimlanes and subprocess containers.

## Do's and Don'ts

### ✅ Do
- Change data only via the model inside a transaction (`diagram.commit` / `startTransaction`+`commitTransaction`) so undo/redo and re-binding work.
- Use `makeTwoWay()` on bindings whose values users can edit (position, text) to persist edits back to the model.
- Define one template and let bindings vary appearance by data — don't build nodes imperatively.
- Serialize with `model.toJson()`; it captures exactly the model, not the rendered canvas.

### ❌ Don't
- Don't mutate `GraphObject` visual props directly for data-driven state — bind them; direct mutation isn't tracked by undo and gets overwritten on rebind.
- Don't ship to production without a license — the eval watermark/terms apply otherwise.
- Don't forget `nodeTemplate` must be a `go.Node` (or `go.Group`/`go.Part`), and `linkTemplate` a `go.Link` — mismatched roots silently fail to render.
- Don't rely on `key` collisions — GoJS auto-assigns keys; set `makeUniqueKeyFunction` if you need custom ids.

## Styling, Theming & Customization
- **Static style**: set properties on `Shape`/`TextBlock` in the template (`fill`, `stroke`, `strokeWidth`, `font`, `figure`).
- **Data-driven style**: `go.Binding('fill', 'field', converter)`.
- **Themes (GoJS 3)**: `diagram.themeManager` with `currentTheme`, and `themeMap`-aware bindings (`new go.Binding('fill', 'color').theme()`) let you swap light/dark palettes centrally.
- **Gradients/brushes**: `fill: $(go.Brush, 'Linear', { 0: '#fff', 1: '#4f8ef7' })`.
- **Selection appearance**: `selectionAdornmentTemplate`, or `{ selectionAdorned: true }`.

## Advanced Features
- **Groups & subgraphs**: `go.Group` with a `Placeholder` for containers, collapsible via `SubGraphExpanderButton`.
- **Undo/redo**: `undoManager.isEnabled = true`; every model change in a transaction is undoable.
- **Virtualization**: for very large diagrams, virtualized layouts render only what's in view.
- **Export**: `diagram.makeImageData({ scale, background })` for PNG, or `makeSvg()` for SVG output.
- **Overview & inspector**: `go.Overview` mini-map; extension inspectors for editing data.

## Performance & Limits
- **Thousands of parts** render comfortably; beyond ~5–10k, enable **virtualization** (a virtualizing layout renders only parts in the viewport) and avoid per-part complex templates.
- **Template cost**: every extra `GraphObject` in a node template multiplies across all nodes. Keep templates lean; use `Picture`/`Shape` over deeply nested panels for large models.
- **Layout cost**: `LayeredDigraphLayout` and `ForceDirectedLayout` are the expensive ones; `TreeLayout`/`GridLayout` are cheap. Run layout once and cache node locations (`makeTwoWay` on `location`) so reloads skip re-layout.
- **Transactions batch**: wrap bulk model edits in a single transaction so the diagram lays out/redraws once, not per change.
- **Animation**: disable `animationManager` for very large diagrams to skip morph animations.

## Integration Notes
- **React/Angular/Vue**: yWorks ships official wrappers (`gojs-react` with `<ReactDiagram>`/`<ReactPalette>`). The wrapper wants an immutable model-diffing pattern — feed it plain node/link data arrays and let it apply incremental model changes; don't mutate GoJS objects directly from React state.
- **Persistence**: `model.toJson()` / `go.Model.fromJson()` round-trips the model (not the view). Store that JSON; rebuild the diagram from it.
- **Server/headless**: GoJS needs a DOM canvas; for server-side image generation yWorks documents a Node + `canvas`/puppeteer approach.
- **Extensions**: the GitHub `extensions`/`extensionsJSM` folders provide non-core tools (drag-create, guided-dragging, non-realtime dragging, inspectors) you copy into your project.

## Common Pitfalls & Troubleshooting
- **Nothing appears**: the diagram div needs a width/height in CSS; the model keys must match link `from`/`to`.
- **Edits don't persist**: binding isn't `makeTwoWay()`, or you mutated data outside a transaction.
- **Undo does nothing**: `undoManager.isEnabled` is false, or changes weren't wrapped in `commit`/transaction.
- **`$ is not a function`**: you didn't alias `go.GraphObject.make` (or you're mixing it with builder syntax).
- **Version drift**: GoJS 2 → 3 changed some defaults and added themeManager; check the version in your CDN URL matches the docs you're following.

## Best For / Avoid For
`flowchart`, `bpmn`, `org-chart`, `state-machine`, `enterprise-diagramming`, `interactive-editor`, `undo-redo` — choose GoJS when you need a polished, editable, commercially-supported diagram surface.
Avoid for: budget/open-source-only projects (use `cytoscape_js` or `vis_js`), pure large-scale analysis rendering (use `sigma_js`), or when you only need a static picture.

## See Also
- `cytoscape_js.md` — open-source graph library with algorithms + styling.
- `vis_js.md` — open-source interactive network with physics.
- `yfiles.md` — the other major commercial option, strongest automatic layouts.
- `../use-case/networks-graphs.md` — choosing among network/graph tools.
