# PlayCanvas — entity-component 3D/game engine for the web

PlayCanvas is a full WebGL/WebGL2/WebGPU game engine built around an **entity-component-system (ECS)**: a scene is a tree of `Entity` objects, and behavior comes from components (`camera`, `light`, `render`, `rigidbody`, `script`, `sound`, `element`). It ships as an open-source runtime (`playcanvas` on npm) and a cloud editor with real-time collaboration. It's known for small builds, strong mobile performance, and production use in games, ads, and configurators.

**Current Version**: engine `1.7x` / `2.x` line (npm `playcanvas`, "current major") **License**: MIT (engine; editor is a hosted service) **Bundle/Runtime**: ~350 KB gz core; modular. Renders to a `<canvas>` via WebGL2 (WebGPU experimental).

## Official Resources & Documentation
- **Site**: https://playcanvas.com/
- **Engine docs / API**: https://api.playcanvas.com/ and https://developer.playcanvas.com/
- **Repo**: https://github.com/playcanvas/engine
- **Editor**: https://playcanvas.com/ (cloud) — real-time collaborative scene builder
- **Examples**: https://playcanvas.github.io/
- **PlayCanvas React / Web Components**: https://github.com/playcanvas (newer declarative wrappers)

## Installation & Setup

### Package manager (code-first / engine-only)
```bash
npm install playcanvas
```

### CDN
```html
<script src="https://code.playcanvas.com/playcanvas-stable.min.js"></script>
```

### Imports (ESM engine)
```javascript
import * as pc from 'playcanvas';
// or named: import { Application, Entity, Color, Vec3 } from 'playcanvas';
```
Two workflows exist: **Editor** (assets + scenes authored in the cloud, code in script components) and **engine-only** (everything in code, as below). This doc covers engine-only syntax; Editor projects use the same component API from within scripts.

## Core Syntax / API Reference

### Application & loop
`AppBase`/`Application` owns the canvas, asset registry, systems, and update loop.
```javascript
const canvas = document.getElementById('application');
const app = new pc.Application(canvas, {
  mouse: new pc.Mouse(canvas),
  touch: new pc.TouchDevice(canvas),
  keyboard: new pc.Keyboard(window),
});
app.setCanvasFillMode(pc.FILLMODE_FILL_WINDOW);
app.setCanvasResolution(pc.RESOLUTION_AUTO);
app.start();
app.on('update', (dt) => { /* per-frame, dt in seconds */ });
```

### Entities & the scene graph
```javascript
const e = new pc.Entity('name');
e.setPosition(0, 1, 0);
e.setEulerAngles(0, 45, 0);
e.setLocalScale(1, 1, 1);
app.root.addChild(e);       // add to scene
parent.addChild(child);     // hierarchy = transform parenting
```

### Components (the "C" in ECS)
```javascript
// Camera
const camera = new pc.Entity('camera');
camera.addComponent('camera', { clearColor: new pc.Color(0.1, 0.12, 0.18) });
camera.setPosition(0, 2, 5); camera.lookAt(0, 0, 0);

// Light
const light = new pc.Entity('light');
light.addComponent('light', { type: 'directional', color: pc.Color.WHITE, intensity: 1, castShadows: true });
light.setEulerAngles(45, 30, 0);

// Render (mesh) — modern component; replaces legacy 'model'
const box = new pc.Entity('box');
box.addComponent('render', { type: 'box' });   // box|sphere|cylinder|cone|plane|capsule|torus + asset
const mat = new pc.StandardMaterial();
mat.diffuse = new pc.Color(1, 0.3, 0.2);
mat.update();
box.render.meshInstances.forEach(mi => mi.material = mat);

// Physics
box.addComponent('rigidbody', { type: 'dynamic', mass: 1 });
box.addComponent('collision', { type: 'box', halfExtents: new pc.Vec3(0.5, 0.5, 0.5) });

// Script
box.addComponent('script');
```
Component families: `camera`, `light`, `render`, `model` (legacy), `rigidbody`, `collision`, `script`, `sound`, `audiolistener`, `element` (UI), `screen`, `particlesystem`, `anim`, `sprite`, `button`, `layoutgroup`.

### Scripts (behavior)
```javascript
const Rotate = pc.createScript('rotate');
Rotate.attributes.add('speed', { type: 'number', default: 30 });
Rotate.prototype.update = function (dt) {
  this.entity.rotate(0, this.speed * dt, 0);
};
box.script.create('rotate', { attributes: { speed: 45 } });
```

### Materials
```javascript
const m = new pc.StandardMaterial();     // PBR: diffuse/metalness/gloss/normal/emissive
m.diffuse.set(0.9, 0.2, 0.2);
m.metalness = 0.1; m.useMetalness = true;
m.gloss = 0.6;
m.diffuseMap = texture; m.normalMap = normalTex;
m.update();                              // REQUIRED after property changes
// Also: pc.BasicMaterial (unlit), custom shaders via pc.ShaderMaterial / chunks.
```

### Loading assets
```javascript
app.assets.loadFromUrl('model.glb', 'container', (err, asset) => {
  const inst = asset.resource.instantiateRenderEntity();
  app.root.addChild(inst);
});
```

## Output Types / Use Cases
- **HTML5 games** (2D via sprite/element, 3D via render/anim).
- **Product visualizations / configurators**.
- **Interactive ads** (small builds matter here).
- **Mobile web 3D** (strong perf/size profile).
- **Collaborative real-time 3D** via the editor.

## How-To

### How to add colors, materials & lighting (mandatory styling recipe)
Color is a `pc.Color` (0–1 RGBA) on a material; realistic shading needs `StandardMaterial` + lights (+ optionally a skybox/env for reflections). Always call `material.update()` after edits.
```javascript
// Lit PBR sphere
const sphere = new pc.Entity();
sphere.addComponent('render', { type: 'sphere' });
const mat = new pc.StandardMaterial();
mat.diffuse = new pc.Color(0.31, 0.55, 1.0);
mat.useMetalness = true; mat.metalness = 0.1; mat.gloss = 0.6;
mat.emissive = new pc.Color(0.0, 0.02, 0.08);
mat.update();
sphere.render.meshInstances[0].material = mat;
app.root.addChild(sphere);

// Ambient + key light + skybox reflections
app.scene.ambientLight = new pc.Color(0.15, 0.17, 0.2);
const key = new pc.Entity();
key.addComponent('light', { type: 'directional', intensity: 2, castShadows: true });
key.setEulerAngles(50, 20, 0);
app.root.addChild(key);
// app.scene.envAtlas / skybox for image-based lighting (set via loaded cubemap/HDR)
app.scene.toneMapping = pc.TONEMAP_ACES;
app.scene.gammaCorrection = pc.GAMMA_SRGB;
```
`toneMapping` + `gammaCorrection = GAMMA_SRGB` give correct on-screen color, exactly as with three.js.

### How to spin / animate an entity
```javascript
app.on('update', (dt) => box.rotate(0, 40 * dt, 0));   // dt-scaled
```
For skeletal/keyframe animation use the `anim` component + state graph; for tweening use `pc.Application`'s tween library or manual lerp in `update`.

### How to handle input / picking
```javascript
app.mouse.on(pc.EVENT_MOUSEDOWN, (e) => {
  const from = camera.camera.screenToWorld(e.x, e.y, camera.camera.nearClip);
  const to   = camera.camera.screenToWorld(e.x, e.y, camera.camera.farClip);
  const hit  = app.systems.rigidbody.raycastFirst(from, to);
  if (hit) hit.entity.render.meshInstances[0].material.diffuse.set(1, 1, 0);
});
```

### How to add physics
```javascript
// (requires ammo.js loaded) dynamic body falling onto a static ground
ground.addComponent('rigidbody', { type: 'static' });
ground.addComponent('collision', { type: 'box', halfExtents: new pc.Vec3(5, 0.1, 5) });
```

## Do's and Don'ts

### ✅ Do
- Call `material.update()` after changing any material property.
- Prefer the `render` component over the deprecated `model` component.
- Scale motion by `dt` for frame-rate independence.
- Use `instantiateRenderEntity()` from a loaded GLB container.
- Set `gammaCorrection = GAMMA_SRGB` + a tone mapping mode for correct color.

### ❌ Don't
- Don't forget `material.update()` — edits silently won't apply.
- Don't add `rigidbody`/`collision` without ammo.js loaded — physics silently no-ops.
- Don't build heavy scenes for mobile without texture compression (Basis/KTX2) and LODs.
- Don't confuse Editor-only concepts (asset registry UI) with engine-only code — both use the same component API but assets differ.
- Don't mutate transforms via the matrix directly — use `setPosition`/`rotate`/`setLocalScale`.

## Styling, Theming & Customization
- **Skybox / IBL**: load a cubemap or HDR, assign to `app.scene.skybox` / `envAtlas` for reflections and ambient.
- **Tone mapping**: `TONEMAP_LINEAR | FILMIC | HEJL | ACES | ACES2 | NEUTRAL`.
- **Fog**: `app.scene.fog = pc.FOG_LINEAR`, plus `fogColor`, `fogStart`, `fogEnd`.
- **Post-processing**: post-effect scripts (bloom, SSAO, vignette, FXAA) or the newer render-pass system.
- **Custom shaders**: `pc.ShaderMaterial` or override StandardMaterial chunks.

## Advanced Features
- **Physics**: Ammo (Bullet) via rigidbody/collision + joints/triggers.
- **Anim state graph**: blend trees, layers, events for characters.
- **UI**: `screen` + `element` + `button`/`layoutgroup` for in-canvas UI.
- **Particles**: GPU `particlesystem` component.
- **WebXR**: `app.xr` for VR/AR sessions.
- **Batching / layers**: draw-call batching and custom render layers for perf.

## Component quick-reference
| Component | Adds | Key options |
|---|---|---|
| `camera` | viewpoint | `clearColor`, `fov`, `projection`, `priority` |
| `light` | light source | `type` (directional/point/spot), `color`, `intensity`, `castShadows` |
| `render` | mesh (modern) | `type` (box/sphere/…/asset), `material`, `castShadows` |
| `rigidbody` | physics body | `type` (static/dynamic/kinematic), `mass`, `friction` |
| `collision` | collider | `type` (box/sphere/mesh/capsule), `halfExtents` |
| `script` | behavior | attaches `createScript` classes |
| `sound` | audio source | `slots`, `positional` |
| `element`/`screen` | UI | text/image elements, anchors, `layoutgroup` |
| `particlesystem` | GPU particles | `numParticles`, `lifetime`, `rate` |
| `anim` | animation state graph | blend trees, layers, events |

## Common Pitfalls & Troubleshooting
- **Material change doesn't show** — missing `material.update()`.
- **Black/flat objects** — no lights + `StandardMaterial`, or no skybox for metallic reflections; add ambient/directional light.
- **Physics does nothing** — ammo.js not loaded, or collision component missing/mismatched.
- **Nothing renders** — no camera component, or camera not added to `app.root`, or fill mode not set.
- **Colors too bright/dark** — gamma/tone mapping not set (`GAMMA_SRGB` + a tonemap).
- **Legacy tutorials use `model` + `material` component** — modern engine uses `render` component + material on mesh instances.

## Integration Notes
- Editor projects publish to PlayCanvas hosting or export a downloadable build embeddable anywhere.
- Engine-only projects bundle with Vite/webpack like any npm dep; load ammo.js and Basis/KTX2 decoders as static assets.
- React usage via community `@playcanvas/react` wrapper or plain refs.

## Best For / Avoid For
`html5-games`, `mobile-web-3d`, `product-visualization`, `interactive-ads`, `collaborative-3d` — choose PlayCanvas for game-grade features (physics, ECS, UI) with small builds and strong mobile perf.
Avoid for: React-idiomatic declarative scenes (use R3F), pure no-code artist workflows (Spline/Verge3D), or when the team already standardizes on three.js and wants its ecosystem.

## See Also
- `three_js.md` — the other dominant WebGL library (retained-mode scene graph)
- `react-three-fiber.md` — declarative React 3D
- `webgl.md` — raw layer beneath all of these
- `verge3d.md`, `spline.md` — editor-driven 3D
- `../use-case/3d-graphics.md` — 3D solution selection
