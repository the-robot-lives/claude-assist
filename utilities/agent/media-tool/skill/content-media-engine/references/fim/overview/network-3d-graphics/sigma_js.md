# Sigma.js

## What
Sigma.js is a high-performance, WebGL-powered graph rendering library optimized for displaying large networks with thousands of nodes. It renders node-edge graphs backed by the `graphology` graph data model. Primary consumer is browser JavaScript (WebGL).

## How
- The LLM emits JavaScript that builds a `graphology` `Graph` (adding nodes with `x`/`y`/`size`/`label`/`color` and edges), then instantiates `new Sigma(graph, container, options)` with render options such as `renderLabels`/`renderEdgeLabels`.
- Turned into a viewable artifact via npm (`npm install sigma graphology graphology-layout-forceatlas2`) or a CDN `<script>` include of `sigma.min.js`, mounted into a container element.
- Typical final artifact: an interactive WebGL graph canvas with smooth pan/zoom.

## Why
- Reach for Sigma.js when scale is the priority: large network visualizations, social graphs, knowledge graphs, and real-time network monitoring. Strengths are WebGL rendering of 10K+ nodes, smooth pan/zoom, an extensible plugin system, memory efficiency, and included force-directed layouts.
- Limitations: a learning curve for the graphology model, limited built-in layouts, and a WebGL dependency that excludes older browsers.
- Versus [[cytoscape_js]] / [[vis_js]] — Sigma trades their richer algorithm/interaction surface for raw rendering scale; choose it when node count, not analysis breadth, is the constraint.

## Source
- Solution reference: `fim/solution/sigma_js.md`
