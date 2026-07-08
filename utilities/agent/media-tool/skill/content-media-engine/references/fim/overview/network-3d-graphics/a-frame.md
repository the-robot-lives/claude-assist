# A-Frame

## What
A-Frame is an open-source web framework for building virtual reality and augmented reality experiences using an HTML-like declarative syntax. It works across desktop, mobile, and VR headsets on standard web technologies (WebXR/WebGL, built on Three.js). Primary consumer is browser HTML/JavaScript. MIT licensed.

## How
- The LLM emits declarative HTML markup: an `<a-scene>` containing entities (`<a-entity>`) composed from components (`geometry`, `material`, `position`, `animation`), an `<a-assets>` block for preloaded textures/models/audio, using A-Frame's Entity-Component-System model.
- Turned into a viewable artifact via a CDN `<script>` include of `aframe.min.js` (or `npm install aframe`), served from a local dev server (live-server/http-server/webpack-dev-server) — the scene renders in-browser and enters VR/AR via WebXR.
- Typical final artifact: an interactive in-browser WebGL scene, optionally an immersive WebXR (VR/AR) session.

## Why
- Reach for A-Frame for WebXR-first, cross-platform immersive content: WebXR apps, educational VR, 360° media, rapid VR/AR prototyping, and entry-level VR development where HTML-familiar syntax lowers the barrier. Strengths are declarative markup, a large component ecosystem, and single-codebase desktop/mobile/VR deployment.
- Limitations: ECS overhead versus pure Three.js, mobile performance ceilings, limited low-level rendering control, harder custom-shader integration, and WebXR/iOS AR restrictions.
- Versus [[three_js]] — A-Frame sits on top of Three.js, trading low-level control for declarative, VR-focused ergonomics.

## Source
- Solution reference: `fim/solution/a-frame.md`
