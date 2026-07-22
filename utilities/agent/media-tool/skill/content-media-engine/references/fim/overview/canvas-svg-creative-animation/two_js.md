# Two.js

## What
A two-dimensional drawing library with a single unified API that renders to SVG, Canvas, or WebGL interchangeably, built around a scene graph, shape primitives, and a built-in animation loop. Its consumer is the browser, with the renderer chosen at construction.

## How
- The LLM emits Two.js JavaScript that constructs a renderer and makes shapes: `const two = new Two({width:640, height:480}).appendTo(document.body)`, then `two.makeCircle(70,100,50)`, `two.makeRectangle(...)`, `two.makeStar(...)`, `two.makePath(anchors, true)`, grouped via `two.makeGroup(...)`.
- Load via CDN (`two.min.js`) or `import Two from 'two.js'`. Animation is driven by `two.bind('update', function(frameCount){...})` and started with `two.play()`; shapes are retained objects whose properties you mutate per frame.
- Typical final artifact: an animated 2D scene rendered as SVG, Canvas, or WebGL from the same code — the renderer is a swappable target.

## Why
- Reach for Two.js when you want a clean scene-graph shape API but don't want to commit to one rendering backend — the same drawing code can output SVG (crisp/inspectable), Canvas (fast raster), or WebGL (GPU) by changing the renderer type.
- Limitations: it is a drawing/animation library, not a geometry engine (no boolean path operations) and not a physics or timeline-orchestration tool; its abstraction sits above the primitives rather than exposing low-level pixel control.
- Relative to siblings: two_js is the renderer-agnostic option. Choose it over svg_js (SVG-only) or paper_js (Canvas-only) when backend flexibility matters; choose those instead when you specifically need SVG DOM semantics or boolean vector math.

## Source
- Solution reference: `fim/solution/two_js.md`
