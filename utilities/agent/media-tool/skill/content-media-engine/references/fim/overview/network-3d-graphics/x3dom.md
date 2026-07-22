# X3DOM

## What
X3DOM enables declarative 3D content inside HTML using X3D scene-graph concepts, with no browser plugins. It renders 3D scenes described as HTML-embedded X3D markup. Primary consumer is browser HTML/JavaScript.

## How
- The LLM emits declarative markup: an `<x3d>` element containing a `<scene>` with a `<viewpoint>`, `<shape>` nodes (each with `<appearance>`/`<material>` and geometry like `<box>`/`<sphere>`), and `<transform>` wrappers for positioning/rotation.
- Turned into a viewable artifact via a CDN `<link>` to `x3dom.css` and `<script>` to `x3dom.js`; the runtime parses the X3D markup and renders it to WebGL in the page.
- Typical final artifact: an interactive in-page WebGL 3D scene driven by HTML markup.

## Why
- Reach for X3DOM when you want plugin-free declarative 3D embedded in HTML, especially with CAD/standards-based content: X3D/VRML CAD models, geospatial coordinates, and touch-device support. It integrates 3D into HTML5 without imperative rendering code.
- Best practices from the source: inline geometry for simple shapes, external files for complex models, LOD nodes for performance, and binary geometry for large datasets.
- Versus [[a-frame]] — both are declarative HTML 3D approaches, but X3DOM follows the X3D/VRML scene-graph standard and CAD lineage, while A-Frame is a WebXR-focused ECS framework on Three.js.

## Source
- Solution reference: `fim/solution/x3dom.md`
