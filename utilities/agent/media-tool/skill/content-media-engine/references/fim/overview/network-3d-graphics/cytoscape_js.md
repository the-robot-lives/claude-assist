# Cytoscape.js

## What
Cytoscape.js is a professional-grade graph theory and network visualization library for interactive data visualization in the browser. It renders interactive node-edge graphs (Canvas 2D with WebGL fallbacks) and ships a rich graph-algorithm library (A*, Dijkstra, betweenness centrality, PageRank, community detection). Primary consumer is browser JavaScript, framework-agnostic (React/Vue/Angular/vanilla).

## How
- The LLM emits JavaScript/TypeScript that constructs a Cytoscape instance from `elements` (nodes/edges), a `style` block, and a `layout` — optionally selecting a layout extension per network type (cose-bilkent, dagre, cola, elk, fcose, klay).
- Turned into a viewable artifact via npm (`npm install cytoscape` plus layout extensions) or CDN `<script>` includes of `cytoscape.min.js` and any extension bundles, mounted into a container element.
- Typical final artifact: an interactive Canvas graph in the DOM, with high-quality PNG/JPG/SVG export available.

## Why
- Reach for Cytoscape.js when you need a full-featured, extensible network app: social-network analysis, knowledge graphs, workflow/dependency systems, biological networks, infrastructure mapping. Strengths are its 40+ extension ecosystem, rich algorithms, mobile touch support, and export capabilities.
- Limitations: steep learning curve, high memory use beyond ~2000 nodes without optimization, verbose styling, and ~400KB bundle for the full feature set. Source explicitly says to avoid it for simple hierarchical trees, purely static diagrams, >1000 updates/sec streaming, and geospatial networks.
- Versus lighter siblings — it is heavier and more capable than [[vis_js]] or [[sigma_js]]; choose Sigma when raw WebGL scale (10K+ nodes) matters more than the algorithm/extension surface.

## Source
- Solution reference: `fim/solution/cytoscape_js.md`
