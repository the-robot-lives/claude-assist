# Graphviz

## What
Graphviz is graph-visualization software for directed and undirected graphs, and the industry standard for laying out node-and-edge structures. It is consumed via CLI, a Python binding, or a JavaScript wrapper, and ships multiple automatic layout engines (dot, neato, fdp, circo, twopi).

## How
- The LLM emits DOT-language markup (e.g. a `digraph G { ... }` with node/edge definitions and shape/style attributes).
- That markup is turned into a viewable artifact by installing Graphviz (`brew install graphviz`, `apt-get install graphviz`), or via bindings such as the `graphviz` pip package or the `@aduh95/viz.js` npm wrapper, then running a layout engine over the DOT source.
- Typical final artifact: rendered graph image (SVG/PNG/PDF) produced by the chosen layout algorithm.

## Why
- Reach for Graphviz when you need robust automatic layout of large graphs with extensive node/edge styling — best for `dependency-graphs`, `state-machines`, `network-diagrams`, `call-graphs`, and `data-flow-visualization`.
- Limitations: steep learning curve for advanced features, limited interactivity without extra tooling, manual positioning is difficult, and syntax gets complex for nested structures.
- Relative to the DOT-language entry (its closest sibling): Graphviz is the engine/toolset, while `graphviz-dot` documents the DOT language itself as the declarative input format that engine consumes.

## Source
- Solution reference: `fim/solution/graphviz.md`
