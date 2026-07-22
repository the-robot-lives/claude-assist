# D3.js

## What
D3.js (Data-Driven Documents) is the industry-standard low-level JavaScript library for building sophisticated, interactive data visualizations on the web. It binds data to the DOM and drives scales, axes, transitions, force layouts, geographic projections, and hierarchical layouts directly.

## How
- The LLM emits browser JavaScript built on D3's selection system (`d3.select`/`selectAll`, the enter–update–exit data-join pattern) plus scales (`scaleLinear`, `scaleOrdinal`), axes, and transitions.
- Rendered by installing `d3@7` via npm/yarn (or modular packages like `d3-selection`, `d3-scale`, `d3-axis`, `d3-force`) or loading `https://cdn.jsdelivr.net/npm/d3@7`; integrates with React/Vue/Angular.
- Final artifact: typically bespoke interactive SVG (or Canvas) visualizations in the DOM.

## Why
- Reach for D3 when you need maximum control and fully custom visualizations that off-the-shelf chart libraries can't express — force-directed networks, custom geographic maps, hierarchical/treemap layouts, and finely tuned transitions and brushing.
- Tradeoffs: the steepest learning curve in this category and verbose imperative code; large datasets require explicit performance optimization and memory management.
- Versus Observable Plot / Chart.js it trades ease-of-use for unlimited flexibility; higher-level libraries (Plot, Vega-Lite) exist precisely to avoid D3's boilerplate for common charts. The nested `use-case/` detail covers data-visualization and networks-graphs.

## Source
- Solution reference: `fim/solution/d3_js.md`
- Nested use-case detail: `fim/solution/d3_js/use-case/data-visualization.md`, `fim/solution/d3_js/use-case/networks-graphs.md`
