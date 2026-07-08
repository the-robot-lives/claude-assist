# p5.js

## What
A creative-coding library for interactive graphics and animation, providing an immediate-mode drawing model with a `setup()`/`draw()` lifecycle, easy input handling, and optional WebGL for 3D. Its consumer is the browser canvas; output is animated/interactive canvas graphics.

## How
- The LLM emits a p5.js sketch: a global `function setup(){ createCanvas(400,400); }` and a `function draw(){ background(220); ... }` loop using drawing calls like `fill()`, `circle(mouseX, mouseY, 50)`, `rect(...)`.
- Load via CDN (`p5.min.js`), `npm install p5`, or the hosted editor at editor.p5js.org. The `draw()` function runs as a continuous animation loop; `mouseX`/`mouseY` and related globals give immediate interaction.
- Typical final artifact: a live interactive canvas sketch (2D or WebGL 3D), suitable for generative art and installations. Also supports sound and video manipulation.

## Why
- Reach for p5.js for generative art, data-art, interactive installations, educational visualizations, and general creative coding — its strengths are immediate-mode animation, built-in interaction handling, particle/physics-friendly patterns, and beginner accessibility.
- Limitations: not optimized for large datasets, limited chart types versus dedicated viz libraries, and performance overhead for simple static visuals.
- Relative to siblings: p5.js is the modern JS creative-coding standard. Choose it over processing_js (which ports classic Processing syntax) when you want idiomatic modern JavaScript and active tooling; choose Paper.js/Two.js instead when you need retained vector objects rather than a redraw-every-frame sketch model.

## Source
- Solution reference: `fim/solution/p5_js.md`
