# Three.js

## What
Three.js is a general-purpose JavaScript 3D library for WebGL graphics. It provides a scene-graph API (scene, camera, geometry, material, mesh, renderer) with WebGL/WebGL2/WebGPU backends and an extensive material, lighting, and VR/AR system. Primary consumer is browser JavaScript.

## How
- The LLM emits Three.js scene-graph JavaScript: create a `THREE.Scene`, a camera (`PerspectiveCamera`), a `WebGLRenderer` appended to the DOM, add meshes (`BoxGeometry` + material), and drive a `requestAnimationFrame` loop calling `renderer.render(scene, camera)`.
- Turned into a viewable artifact via npm (`npm install three`) or an ES-module CDN import of `three.module.js`; the renderer draws into a `<canvas>` on the page.
- Typical final artifact: an interactive real-time WebGL canvas.

## Why
- Reach for Three.js as the default general-purpose 3D library for 3D data visualization, interactive 3D models, VR experiences, game graphics, and scientific simulations. Strengths are full 3D capabilities, WebGL/WebGL2/WebGPU support, a deep material/lighting system, VR/AR support, and a large ecosystem.
- Limitations: complex API for simple tasks, performance overhead for 2D, a large (600KB+) library size, and a required 3D-graphics knowledge base.
- Versus [[babylon_js]] — Three.js is a lower-level, general-purpose 3D toolkit while Babylon is a batteries-included game-engine-style framework. [[react-three-fiber]] wraps Three.js in declarative React components.

## Source
- Solution reference: `fim/solution/three_js.md`
- Nested use-case detail: `fim/solution/three_js/use-case/3d-graphics.md`, `fim/solution/three_js/use-case/creative-animation.md`
