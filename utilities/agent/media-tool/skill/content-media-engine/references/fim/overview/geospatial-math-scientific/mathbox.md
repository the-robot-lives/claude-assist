# MathBox

## What
MathBox is a JavaScript library for animated, interactive 3D mathematical visualization, built on Three.js/WebGL. Its primary consumer is browser JavaScript, loaded via CDN alongside Three.js and the MathBox bundle.

## How
- The LLM emits **MathBox JavaScript** — `MathBox.mathBox({plugins: ['core','controls','cursor'], controls: {klass: THREE.OrbitControls}})`, a `camera`, and a `cartesian` view with `range`/`scale`.
- That runs in the browser: axes/grids are added to the view; surfaces via `view.area({expr: (emit,x,y)=>emit(x, f(x,y), y)}).surface(...)`; animated curves via `view.interval(...).line(...)` driven by a `mathbox.clock()`.
- Typical final artifact: an **interactive, animatable 3D math scene** rendered with WebGL in the browser.

## Why
- Reach for MathBox when you need presentation-grade, animated 3D math in the browser — surfaces, parametric curves, and time-varying visualizations with orbit controls.
- Main tradeoff: it requires a Three.js/WebGL setup and an emit-based data model, and targets interactive on-screen visuals rather than static print figures.
- Relative to its siblings: MathBox is the interactive browser-3D counterpart to `asymptote`'s publication-quality (mostly print) 3D, and unlike the 2D-focused `mathjax`/`katex` it is about spatial visualization rather than notation.

## Source
- Solution reference: `fim/solution/mathbox.md`
