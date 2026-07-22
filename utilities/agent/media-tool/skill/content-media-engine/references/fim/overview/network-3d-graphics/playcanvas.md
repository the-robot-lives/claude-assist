# PlayCanvas

## What
PlayCanvas is a 3D web-apps engine for building games and interactive 3D experiences, with an entity-component API and a cloud-based editor. It renders real-time WebGL 2.0 scenes. Primary consumer is browser JavaScript.

## How
- The LLM emits JavaScript that creates a `pc.Application(canvas)`, sets fill mode/resolution, `app.start()`, then adds entities with components (`camera`, `light`, `model`, `material`, `script`) to `app.root` and updates them in an `app.on('update', dt => …)` loop.
- Turned into a viewable artifact via npm (`npm install playcanvas`) or a CDN `<script>` include of `playcanvas-stable.min.js`, rendering into a `<canvas>`; a cloud editor workflow is also available.
- Typical final artifact: an interactive real-time WebGL canvas.

## Why
- Reach for PlayCanvas when targeting lightweight, mobile-friendly 3D: HTML5 games, product visualizations, interactive advertisements, mobile web experiences, and real-time collaborative 3D. Strengths are its light/performant runtime, cloud-based editor, WebGL 2.0 support, real-time collaboration, and strong mobile performance.
- Limitations: a smaller community than Three.js, an editor-centric workflow that may not suit all projects, and limited third-party plugins.
- Versus [[babylon_js]] / [[three_js]] — PlayCanvas is engine-class like Babylon but leans on a collaborative cloud editor and mobile efficiency rather than a purely code-first setup.

## Source
- Solution reference: `fim/solution/playcanvas.md`
