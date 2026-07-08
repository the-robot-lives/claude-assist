# Zdog

## What
Zdog is a pseudo-3D engine for canvas and SVG that renders round, flat-shaded 3D-look illustrations. It is not a true 3D engine (no perspective projection) but positions and rotates simple shapes in 3D space. Primary consumer is browser JavaScript.

## How
- The LLM emits JavaScript that creates a `Zdog.Illustration` bound to a `.zdog-canvas` (or `.zdog-svg`) element, adds primitives (`Zdog.Box`, `Zdog.Ellipse`, `Zdog.Cone`, `Zdog.Shape`, grouped via `Zdog.Group`), and animates by incrementing `rotate` values inside a `requestAnimationFrame` loop calling `illo.updateRenderGraph()`.
- Turned into a viewable artifact via npm (`npm install zdog`) or a CDN `<script>` include of `zdog.dist.min.js`; it can render to either `<canvas>` or SVG.
- Typical final artifact: an animated canvas or SVG pseudo-3D illustration.

## Why
- Reach for Zdog when you want a charming flat-shaded 3D look at tiny cost: logos and icons with a 3D feel, simple interactive illustrations, depth-based data visualization, and loading animations. Strengths are its ~8KB size, friendly API, canvas+SVG output, and zero dependencies.
- Limitations: not true 3D (no perspective projection), limited to simple geometries, no textures/materials, no lighting system, and performance limits with many objects.
- Versus real 3D engines like [[three_js]] — Zdog is a stylized illustration tool, not a general 3D renderer; choose it for aesthetic simplicity, not fidelity.

## Source
- Solution reference: `fim/solution/zdog.md`
