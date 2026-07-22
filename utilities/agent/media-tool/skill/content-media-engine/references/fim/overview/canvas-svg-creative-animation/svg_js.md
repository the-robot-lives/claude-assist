# SVG.js

## What
A lightweight library for creating, manipulating, and animating SVG through a chainable DOM API, with grouping, gradients, patterns, masks/clips, events, a plugin system, and a timeline. Its consumer is the browser DOM; output is live SVG elements.

## How
- The LLM emits SVG.js JavaScript that builds an SVG document and chains operations: `const draw = SVG().addTo('#drawing').size(300,300)`, then `draw.rect(100,100).fill('#f06')`, `draw.circle(100).move(50,50)`, `draw.path('M 100 50 L 200 150 Z')`, `draw.text('SVG.js').font({...})`.
- Load via CDN (`@svgdotjs/svg.js@3.0/dist/svg.min.js`) or `import { SVG } from '@svgdotjs/svg.js'`. Animation is built in — `rect.animate(1000).move(100,100).rotate(45)` and an `SVG.Timeline` for sequencing; `.on('click', ...)` wires events.
- Typical final artifact: an interactive, animated SVG in the DOM — icons, illustrations, path-following motion, resolution-independent vector graphics.

## Why
- Reach for SVG.js when you specifically want *SVG* output (crisp at any scale, DOM-inspectable, CSS-stylable) with a friendly manipulation and animation API and a small footprint.
- Limitations: it is SVG-only (no Canvas/WebGL fallback), so very large numbers of elements hit DOM performance limits; it is a manipulation/animation helper rather than a geometry engine (no boolean path ops like Paper.js).
- Relative to siblings: svg_js is the lightweight SVG DOM specialist. Choose it over paper_js when you want native SVG rather than canvas rendering and don't need boolean/bezier math; choose Two.js when you want the same shapes but renderer-agnostic across SVG/Canvas/WebGL.

## Source
- Solution reference: `fim/solution/svg_js.md`
