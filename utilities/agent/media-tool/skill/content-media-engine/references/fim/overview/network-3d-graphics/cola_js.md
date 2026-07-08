# Cola.js (WebCola)

## What
Cola.js (WebCola) is a constraint-based graph layout library for the browser. It computes node positions for network visualizations — supporting alignment constraints, hierarchical grouping, and overlap avoidance — and pairs with D3.js for the actual SVG rendering. Primary consumer is browser JavaScript.

## How
- The LLM emits JavaScript that builds `nodes`, `links`, and `constraints` arrays and drives a `cola.d3adaptor(d3)` layout (`.size()`, `.nodes()`, `.links()`, `.constraints()`, `.linkDistance()`, `.avoidOverlaps(true)`, `.start()`).
- Turned into a viewable artifact via npm (`npm install webcola`) or a CDN `<script>` include of `cola.min.js`, then bound to an existing D3 SVG selection — Cola computes geometry, D3 draws the `.node`/`.link` elements.
- Typical final artifact: an interactive SVG network diagram in the DOM.

## Why
- Reach for Cola.js when the layout has hard positioning requirements: UML diagrams, hierarchical networks, alignment/grouping constraints, and academic visualizations where overlap prevention matters. Its advanced constraint system and academic backing are the differentiators.
- Limitations: steeper learning curve, less active development, and limited documentation.
- Versus [[d3-force]] — both position nodes for D3-rendered graphs, but d3-force is a customizable physics simulation while Cola adds a formal constraint solver (alignment, grouping, overlap) on top.

## Source
- Solution reference: `fim/solution/cola_js.md`
