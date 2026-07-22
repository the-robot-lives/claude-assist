# Paper.js

## What
An open-source (MIT) vector-graphics scripting framework for the HTML5 Canvas, built around a hierarchical scene graph with bezier paths, boolean path operations, symbols, layers, and a Point/Size/Rectangle/Matrix math foundation. Its consumer is the browser Canvas (also usable server-side via node-canvas); output is retained vector objects rendered to canvas.

## How
- The LLM emits Paper.js JavaScript that constructs retained objects: `new paper.Path.Circle({center, radius, fillColor})`, `new paper.CompoundPath(...)`, boolean ops like `circle1.unite(circle2)`, and `new paper.PointText(...)`.
- Load via CDN (`paper-full.min.js`) or `npm install paper`, then bind a canvas with `paper.setup(canvas)`. Animation uses the built-in `paper.view.onFrame = function(event){...}`; interaction uses `new paper.Tool()` with `onMouseDown`/`onMouseDrag`.
- Typical final artifact: an interactive canvas scene; can also export SVG or serialize the project, and paths can be converted from text for advanced manipulation.

## Why
- Reach for Paper.js when you need a proper vector scene graph on canvas: complex path/bezier math, boolean geometry, groups/layers, hit-testing, and interactive drawing tools — strong for custom data-viz, generative art, and 2D interactive media.
- Limitations: it is Canvas-only with no WebGL/GPU acceleration, single-threaded, and performance degrades into the thousands of objects; advanced typography is limited and the full library is relatively large (~200KB minified).
- Relative to siblings: Paper.js is the vector/scene-graph specialist. Choose it over the raw canvas-api when you want retained objects and boolean path math; choose Two.js instead when you need the same scene-graph feel but with renderer-agnostic SVG/Canvas/WebGL output, and p5.js when the goal is sketch-style creative coding rather than precise vector geometry.

## Source
- Solution reference: `fim/solution/paper_js.md`
