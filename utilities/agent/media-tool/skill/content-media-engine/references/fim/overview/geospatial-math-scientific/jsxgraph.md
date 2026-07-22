# JSXGraph

## What
JSXGraph is a JavaScript library for interactive geometry, function plotting, and data visualization in the browser. Its primary consumer is browser JavaScript, loaded via CDN (CSS + `jsxgraphcore.js`) into a container element.

## How
- The LLM emits **JSXGraph JavaScript** — `JXG.JSXGraph.initBoard('jxgbox', {boundingbox, axis, grid})`, then create elements: `board.create('point', [1,1], {name})`, `'line'`, `'circle'`, `'functiongraph'`, `'slider'`, `'curve'`, `'integral'`.
- That runs in the browser: points are draggable, sliders parameterize curves, and numeric derivatives/integrals are available via `JXG.Math.Numerics`.
- Typical final artifact: an **interactive in-browser geometry/plotting board**, self-hostable with no API key.

## Why
- Reach for JSXGraph when you want lightweight, self-hosted interactive geometry and function plotting embedded in your own page, with draggable constructions and parameter sliders.
- Main tradeoff: it is a lower-level library — you build constructions element by element, without the packaged UI/CAS of the larger hosted suites.
- Relative to its siblings: JSXGraph is the open, self-hostable, no-key alternative to the hosted `desmos-api` and `geogebra-api` applets, favoring embeddability and control over a turnkey calculator UI.

## Source
- Solution reference: `fim/solution/jsxgraph.md`
