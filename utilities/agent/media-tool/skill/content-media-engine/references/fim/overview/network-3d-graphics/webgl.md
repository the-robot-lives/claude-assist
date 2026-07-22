# WebGL

## What
WebGL is a low-level, GPU-accelerated graphics API exposing OpenGL ES shaders directly in the browser. It is the native browser rendering layer that higher-level 3D libraries build on. Primary consumer is browser JavaScript — no installation, it is a native browser API.

## How
- The LLM emits raw WebGL JavaScript: obtain a `canvas.getContext('webgl2')`, author GLSL vertex/fragment shaders, compile/link them into a shader program, and upload geometry into buffers (`createBuffer`, `bindBuffer`, `bufferData`) with typed arrays.
- Turned into a viewable artifact with no install — it runs against a `<canvas>` in any WebGL-capable browser; WebGL 2 adds compute-like features (transform feedback, instanced rendering, multiple render targets).
- Typical final artifact: a GPU-rendered `<canvas>` scene driven entirely by custom shaders.

## Why
- Reach for raw WebGL when you need direct GPU control that higher-level engines abstract away: custom GLSL shaders, instanced particle rendering, transform feedback, and multiple render targets. Best practices from the source: batch draw calls, use VAOs for state, implement frustum culling, and tune shader precision.
- Tradeoffs: it is the most verbose and lowest-level option — everything (shaders, buffers, matrices) is hand-written, with no scene graph or helpers.
- Versus [[three_js]] / [[babylon_js]] / [[playcanvas]] — those are frameworks layered on top of WebGL; drop to raw WebGL only when you need control or performance they don't expose.

## Source
- Solution reference: `fim/solution/webgl.md`
