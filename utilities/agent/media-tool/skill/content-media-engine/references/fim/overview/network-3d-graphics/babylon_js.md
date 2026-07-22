# Babylon.js

## What
Babylon.js is a powerful, open-source 3D engine for the web, built with TypeScript/JavaScript, providing a complete framework for 3D experiences, games, and applications with WebGL, WebGPU, and WebXR support. Primary consumer is browser JavaScript. Apache-2.0 licensed and Microsoft-backed.

## How
- The LLM emits Babylon.js scene JavaScript/TypeScript that creates an `Engine` on a `<canvas>`, builds a `Scene` with cameras, lights, meshes, and PBR materials, and runs the engine render loop.
- Turned into a viewable artifact via npm (`npm install babylonjs`, plus optional `babylonjs-loaders`, `babylonjs-materials`, `babylonjs-gui`, `babylonjs-havok`, etc.) or CDN `<script>` includes of `babylon.js` and companion libraries, drawing into a full-window `renderCanvas`.
- Typical final artifact: an interactive real-time WebGL/WebGPU canvas, optionally an immersive WebXR session.

## Why
- Reach for Babylon.js when you want a complete, batteries-included engine: 3D web games, product configurators, training simulations, digital twins, architectural/scientific/medical visualization. Strengths are PBR rendering, built-in physics/particles/post-processing/audio, WebXR, strong TypeScript support, visual tools (inspector, node material editor), and enterprise backing.
- Limitations: 2MB+ core library, long load times for complex assets, heavy memory/GPU use, mobile GPU/battery/heat constraints, and a steep learning curve for 3D newcomers.
- Versus [[three_js]] — Babylon is a fuller game-engine-style framework with more built-in systems, where Three.js is a lighter general-purpose 3D library. [[playcanvas]] is a comparable engine with a cloud editor-centric workflow.

## Source
- Solution reference: `fim/solution/babylon_js.md`
