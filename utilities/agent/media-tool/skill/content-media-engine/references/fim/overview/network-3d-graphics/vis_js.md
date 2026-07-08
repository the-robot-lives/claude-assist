# Vis.js Network

## What
Vis.js Network is a browser-based dynamic network visualization library with built-in physics simulation and interaction handling. It renders interactive node-edge graphs with clustering and hierarchical layouts. Primary consumer is browser JavaScript.

## How
- The LLM emits JavaScript that defines `nodes` and `edges` arrays, then constructs `new Network(container, { nodes, edges }, options)` — with `options` configuring `physics` (e.g. `solver: 'forceAtlas2Based'`) and `interaction` (hover, zoom).
- Turned into a viewable artifact via npm (`npm install vis-network`) or CDN includes of `vis-network.min.css` and `vis-network.min.js`, mounted into a container element.
- Typical final artifact: an interactive Canvas network diagram in the DOM.

## Why
- Reach for Vis.js when you want rich interaction out of the box with minimal wiring: interactive network diagrams, organizational charts, dependency graphs, and workflow visualization. Strengths are its built-in physics engines, clustering/hierarchical layouts, extensive configuration, and good documentation.
- Limitations: performance degrades past ~1000 nodes, a large bundle size, and a complex configuration API.
- Versus [[cytoscape_js]] — Vis.js is quicker to stand up for mid-size interactive graphs; Cytoscape offers deeper algorithms/extensions. For 10K+ nodes, prefer [[sigma_js]].

## Source
- Solution reference: `fim/solution/vis_js.md`
