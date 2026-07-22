# D3 Force

## What
D3 Force (`d3-force`) is a physics-based force-simulation module for D3.js that positions nodes in network graphs. It computes node coordinates from configurable forces (link, charge, center, collision) and leaves rendering to D3's SVG selections. Primary consumer is browser JavaScript.

## How
- The LLM emits JavaScript that builds `nodes`/`links` arrays and a `d3.forceSimulation(nodes)` with forces such as `d3.forceLink().id().distance()`, `d3.forceManyBody().strength()`, `d3.forceCenter()`, and `d3.forceCollide().radius()`, then updates positions inside a `simulation.on('tick', …)` callback.
- Turned into a viewable artifact via npm (`npm install d3-force d3-selection`) or a CDN `<script>` include of `d3@7`, with the developer wiring the tick handler to SVG `cx/cy` and line `x1/y1/x2/y2` attributes.
- Typical final artifact: an animated, interactive SVG force-directed graph.

## Why
- Reach for d3-force when you want fine-grained control over the simulation and animation: custom network visualizations, research papers, data journalism, and animated transitions. Strengths are highly customizable forces, smooth animations, and excellent performance within the D3 ecosystem.
- Limitations: requires D3 knowledge, manual rendering setup, and no built-in UI controls.
- Versus [[cola_js]] — both feed D3 rendering, but d3-force is a pure physics simulation whereas Cola layers a constraint solver on top; reach for a higher-level library like [[vis_js]] or [[cytoscape_js]] when you don't want to hand-wire rendering.

## Source
- Solution reference: `fim/solution/d3-force.md`
