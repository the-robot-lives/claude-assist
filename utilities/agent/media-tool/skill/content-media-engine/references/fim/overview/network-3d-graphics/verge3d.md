# Verge3D

## What
Verge3D is a toolkit for creating interactive 3D web applications from Blender, 3ds Max, or Maya scenes without coding, via its visual "Puzzles" scripting. It renders real-time WebGL scenes with AR/VR support through WebXR. Primary consumer is browser JavaScript. A license is required for production use.

## How
- The LLM emits JavaScript that constructs a `new v3d.App('container', 'app.gltf', options)` (SSAO/HDR/preloader), calls `app.loadScene('scene.gltf', …)`, `app.enableControls()`, and `app.run()`, then wires interaction by traversing `app.scene` and adding event listeners to named objects.
- Turned into a viewable artifact via a CDN `<script>` include of `verge3d.js`; scenes are authored in a DCC tool (Blender/Max/Maya) and exported as glTF, with no-code logic built in Puzzles.
- Typical final artifact: an interactive real-time WebGL application, optionally a WebXR AR/VR experience.

## Why
- Reach for Verge3D when the source content is authored by 3D artists in a DCC package and the app logic should be built visually: e-commerce product configurators, interactive showcases, and AR/VR experiences. Strengths are Puzzles visual scripting, tight Blender/Max/Maya integration, WebXR support, and real-time shadows/reflections.
- Tradeoffs: it is a commercial, license-gated product oriented around a DCC-export workflow rather than code-first development.
- Versus [[three_js]] / [[babylon_js]] — Verge3D targets artists and no-code logic on top of glTF assets, where the general engines are code-first developer toolkits.

## Source
- Solution reference: `fim/solution/verge3d.md`
