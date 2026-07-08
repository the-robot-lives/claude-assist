# Observable Plot

## What
Observable Plot is a grammar-of-graphics data-visualization library for JavaScript, built by the makers of D3. It offers a concise API for exploratory visualization that auto-handles scales, axes, and legends while remaining customizable, and emits SVG output.

## How
- The LLM emits browser JavaScript using the `Plot` API (composable marks such as `Plot.dot`, `Plot.line`, wrapped in `Plot.plot({...})`).
- Rendered by importing `@observablehq/plot@0.6` as an ES module from CDN or installing via npm (with `d3` as a peer dependency). For Node.js/server-side rendering it pairs with `jsdom` to supply a `document`.
- Final artifact: an SVG chart element; optimal for datasets under ~100k points.

## Why
- Reach for Observable Plot to cut visualization code 60–80% versus raw D3 while keeping intelligent defaults, built-in statistical transforms (regression, smoothing, density), and crisp accessible SVG — great for EDA and notebook work. ISC-licensed and free.
- Tradeoffs: grammar-of-graphics concepts take learning, advanced customization still requires D3 knowledge, large datasets (>100k) slow down (limited WebGL), and it is SVG-only.
- Versus D3 it trades low-level control for concision; versus Vega-Lite it stays in idiomatic JavaScript rather than a JSON spec.

## Source
- Solution reference: `fim/solution/observable-plot.md`
