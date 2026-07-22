# HTML5 Canvas API

## What
The native browser 2D drawing API — a `getContext('2d')` surface on a `<canvas>` element that exposes immediate-mode primitives (rectangles, arcs, paths, text, gradients, patterns), pixel-level access, and affine transforms. No library dependency; its consumer is any modern browser's Canvas, producing a raster bitmap.

## How
- The LLM emits plain JavaScript that grabs a context and issues draw calls: `const ctx = canvas.getContext('2d')`, then `ctx.fillRect(...)`, `ctx.arc(...)`, `ctx.fillText(...)`, etc.
- That JS runs directly in the browser against a `<canvas>` element sized via `canvas.width/height` — no build step or import. Animation is driven with a `requestAnimationFrame(animate)` loop that `clearRect`s and redraws each frame.
- Typical final artifact: a rasterized canvas bitmap (exportable to PNG via `toDataURL`), or a live animated canvas surface. Pixel buffers are readable/writable through `getImageData`/`putImageData` for filters and effects.

## Why
- Reach for the raw Canvas API when you want zero dependencies, full low-level control, or direct pixel manipulation (invert, fade trails, custom particle systems). It is the substrate that Paper.js, p5.js, Two.js, and Rough.js all build on top of.
- Limitations: it is immediate-mode with no scene graph or retained objects — you manage all state, redraws, and hit-testing yourself; text/typography features are minimal; and there is no built-in animation, easing, or interaction layer.
- Relative to siblings: canvas-api is the bare metal. Choose Paper.js or p5.js when you want a scene graph, object model, and helper abstractions; stay on the raw API when the task is small, performance-critical, or needs pixel access the higher-level libraries hide.

## Source
- Solution reference: `fim/solution/canvas-api.md`
