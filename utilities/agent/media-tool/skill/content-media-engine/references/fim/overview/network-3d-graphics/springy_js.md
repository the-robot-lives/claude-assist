# Springy.js

## What
Springy.js is a lightweight force-directed graph layout library using spring-force physics between nodes. It computes layout and provides a simple renderer hook for Canvas drawing. Primary consumer is browser JavaScript.

## How
- The LLM emits JavaScript that builds a `new Springy.Graph()`, adds nodes/edges (`graph.newNode(...)`, `graph.newEdge(...)`), creates a `Springy.Layout.ForceDirected` (spring stiffness, node repulsion, damping), and starts a `Springy.Renderer` with clear/draw-edge/draw-node callbacks against a `<canvas>`.
- Turned into a viewable artifact via npm (`npm install springy`) or direct `<script>` includes of `springy.js` and `springyui.js`.
- Typical final artifact: an animated Canvas network diagram.

## Why
- Reach for Springy.js when you want the smallest possible dependency for a simple animated graph: simple network diagrams, educational visualizations, and lightweight embedded graphs. Strengths are its ~8KB size, simple API, smooth animations, and zero dependencies.
- Limitations: basic features only, limited layout options, a small community, and minimal documentation.
- Versus [[d3-force]] / [[vis_js]] — Springy is far lighter but far less capable; choose it only when bundle size and simplicity outweigh features.

## Source
- Solution reference: `fim/solution/springy_js.md`
