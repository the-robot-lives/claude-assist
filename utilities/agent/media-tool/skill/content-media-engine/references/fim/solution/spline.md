# Spline — no-code 3D design tool + web runtime

Spline is a collaborative, browser-based 3D design tool (think "Figma for 3D") plus a lightweight web **runtime** that plays exported scenes. Designers model, texture, light, and add interactions/states in the Spline editor, then export a `.splinecode` URL (or a `.splinecode`/GLB file) that the runtime renders on a `<canvas>` and lets you control from JavaScript — reading/writing objects, variables, and events. It's aimed at landing-page hero scenes, product showcases, and interactive 3D without writing shader/scene code.

**Current Version**: `@splinetool/runtime` ~1.9.x / `@splinetool/react-spline` (current major) **License**: Runtime packages MIT; the Spline editor/service is freemium (paid tiers for advanced export/features). **Bundle/Runtime**: runtime ~100–200 KB gz (three.js-based) + the exported scene payload.

## Official Resources & Documentation
- **Site**: https://spline.design/
- **Docs**: https://docs.spline.design/
- **Runtime (vanilla)**: https://www.npmjs.com/package/@splinetool/runtime
- **React**: https://www.npmjs.com/package/@splinetool/react-spline
- **Repo**: https://github.com/splinetool/react-spline
- **Community/examples**: https://spline.design/examples

## Installation & Setup

### Vanilla runtime
```bash
npm install @splinetool/runtime
```

### React
```bash
npm install @splinetool/react-spline @splinetool/runtime
```

### CDN (ES module)
```html
<script type="module">
  import { Application } from 'https://unpkg.com/@splinetool/runtime@latest/build/runtime.js';
</script>
```
You author the scene in the Spline editor and **export a Public URL** (`https://prod.spline.design/XXXX/scene.splinecode`); the runtime loads that.

## Core Syntax / API Reference

### Vanilla: load a scene
```html
<canvas id="canvas3d"></canvas>
<script type="module">
  import { Application } from '@splinetool/runtime';
  const canvas = document.getElementById('canvas3d');
  const app = new Application(canvas);
  await app.load('https://prod.spline.design/YOUR_SCENE_ID/scene.splinecode');
</script>
```

### Access & manipulate objects
```javascript
await app.load(SCENE_URL);
const cube = app.findObjectByName('Cube');        // by editor name
const byId = app.findObjectById('uuid');
cube.position.x = 10;                              // three.js-like Vector3
cube.rotation.y = Math.PI / 4;
cube.scale.set(2, 2, 2);
cube.visible = false;
```

### Events (Spline interactions ↔ JS)
```javascript
app.addEventListener('mouseDown', (e) => { if (e.target.name === 'Button') doThing(); });
app.addEventListener('mouseHover', (e) => {});
app.addEventListener('keyDown', (e) => {});
app.addEventListener('start', (e) => {});         // Spline "Start" event
app.addEventListener('lookAt', (e) => {});
// Trigger a Spline-authored event by name on an object:
app.emitEvent('mouseDown', 'Button');             // (eventType, nameOrId)
app.emitEventReverse('mouseDown', 'Button');
```

### Variables (Spline's data bindings)
```javascript
const score = app.getVariable('score');
app.setVariable('score', score + 10);
app.getVariables();                               // all variables
app.setVariables({ score: 0, level: 2 });
```

### Sizing / responsiveness
```javascript
app.setSize(window.innerWidth, window.innerHeight);
addEventListener('resize', () => app.setSize(innerWidth, innerHeight));
```

### React component
```jsx
import Spline from '@splinetool/react-spline';
export default function Hero() {
  return (
    <Spline
      scene="https://prod.spline.design/YOUR_SCENE_ID/scene.splinecode"
      onLoad={(spline) => { const obj = spline.findObjectByName('Cube'); }}
      onMouseDown={(e) => console.log('clicked', e.target.name)}
      onSplineMouseHover={(e) => {}}
    />
  );
}
```
Next.js: `@splinetool/react-spline/next` provides an SSR-friendly wrapper with a loading placeholder.

## Output / Supported Content
- **Interactive 3D scenes** authored in the editor: meshes, materials, lights, cameras, particles, physics, states, and event-driven interactions.
- **Export targets**: `.splinecode` runtime URL/file (full interactivity), **GLB/GLTF** (static geometry for three.js/others), image/video, and code snippets (React/vanilla/others).
- **Events**: mouseDown/Up, mouseHover, keyDown/Up, start, lookAt, follow, scroll, and custom states/transitions.

## How-To

### How to change colors, materials & lighting (mandatory styling recipe)
Look-and-feel (materials, colors, lighting, environment) is authored **in the Spline editor** — that's the intended workflow. At runtime you can tweak object properties, but material/color control from JS is limited compared to the editor. Where exposed, colors follow three.js `Color`.
```javascript
await app.load(SCENE_URL);
const obj = app.findObjectByName('Sofa');
// Runtime transform tweaks are reliable:
obj.scale.set(1.1, 1.1, 1.1);
obj.rotation.y += 0.2;
// Color/material: prefer driving it via a Spline VARIABLE bound to the material in-editor:
app.setVariable('fabricColor', '#4f8cff');   // if the designer bound this variable to the material
// (Deep material editing from JS is not the supported path — bind variables/states in the editor.)
```
Best practice: in the editor, expose **variables** (e.g. `fabricColor`, `themeHue`) and bind them to materials/lights; then `setVariable` from JS to re-theme. For lighting/HDRI/environment, set it up in the editor before export.

### How to build an interactive configurator
1. In the editor: create material/color **states** and bind them to swatch objects or variables.
2. Export the scene URL.
3. In JS, drive states via events/variables:
```javascript
document.querySelectorAll('.swatch').forEach((el) =>
  el.addEventListener('click', () => app.setVariable('bodyColor', el.dataset.color)));
```

### How to trigger animations/states from the page
```javascript
app.emitEvent('mouseDown', 'PlayButton');   // fire a Spline interaction programmatically
```

### How to drive the scene from page scroll
```javascript
await app.load(SCENE_URL);
const hero = app.findObjectByName('Hero');
addEventListener('scroll', () => {
  const p = scrollY / (document.body.scrollHeight - innerHeight);   // 0..1
  hero.rotation.y = p * Math.PI * 2;                                // spin with scroll
  app.setVariable('scrollProgress', p);   // or feed a bound variable for editor-authored reactions
}, { passive: true });
```

### How to lazy-load a heavy scene (perf)
```javascript
// Only load when the hero enters the viewport
const io = new IntersectionObserver(([entry]) => {
  if (entry.isIntersecting) { app.load(SCENE_URL); io.disconnect(); }
});
io.observe(document.getElementById('canvas3d'));
```

### Runtime API cheat-sheet
```javascript
app.load(url) / app.load(url).then()      // load a scene (returns a promise)
app.findObjectByName(name) / findObjectById(id)
app.emitEvent(type, nameOrId) / emitEventReverse(type, nameOrId)
app.getVariable(name) / setVariable(name, value) / getVariables() / setVariables(obj)
app.addEventListener(type, cb) / removeEventListener(type, cb)
app.setSize(w, h)  app.dispose()
// Event types: mouseDown, mouseUp, mouseHover, keyDown, keyUp, start, lookAt, follow, scroll, collision
// Object props (three.js-like): position{x,y,z}, rotation{x,y,z}, scale, visible, name, id
```

## Do's and Don'ts

### ✅ Do
- Author look, lighting, and interactions in the editor; use JS for orchestration (events, variables, transforms).
- Expose **variables/states** in the editor and drive them from JS for theming/config.
- Name objects clearly — `findObjectByName`/events select by name.
- Lazy-load the scene (IntersectionObserver) — `.splinecode` payloads can be large.
- Export **GLB** instead when you only need static geometry in three.js/R3F (lighter, no Spline runtime).

### ❌ Don't
- Don't expect to build or deeply restyle scenes purely in code — Spline is editor-first; programmatic scene construction is limited.
- Don't deep-edit materials from JS — bind variables/states in the editor instead.
- Don't ship a giant scene on the critical path — it hurts LCP; lazy-load and show a placeholder.
- Don't forget `setSize` on resize, or the canvas will stretch/blur.
- Don't rely on advanced export features without checking your plan tier.

## Styling, Theming & Customization
- **Editor-authored**: materials (PBR), lighting, environment/HDRI, post-effects, particles — all set before export.
- **Runtime theming**: Spline **variables** bound to properties in the editor, changed via `setVariable`.
- **States**: pre-defined material/transform states triggered by events (`emitEvent`) — the sanctioned way to "restyle" at runtime.
- **Canvas**: standard CSS on the host canvas for layout/sizing.

## Advanced Features
- **States & transitions** authored visually (hover/click/scroll-driven).
- **Physics, particles, path-following** in-editor.
- **Variables** as a data layer bridging page ↔ scene.
- **AR / embed** options; camera/scroll interactions.
- **GLB export** to hand off geometry to three.js/R3F/PlayCanvas when you outgrow the runtime.

## Common Pitfalls & Troubleshooting
- **Scene won't load** — wrong/private `.splinecode` URL, CORS, or the scene not re-exported after edits.
- **Object not found** — name mismatch (`findObjectByName` is case/space sensitive) or scene not loaded yet (await `load`).
- **Can't change a color from JS** — deep material edits aren't supported; bind a variable/state in the editor.
- **Blurry/stretched canvas** — missing `setSize` on resize / DPR handling.
- **Slow page / poor LCP** — heavy scene loaded eagerly; lazy-load and optimize the scene in-editor.
- **Next.js hydration/SSR errors** — use `@splinetool/react-spline/next` or client-only dynamic import.

## Integration Notes
- **React**: `@splinetool/react-spline` (`onLoad` gives the app instance). **Next.js**: `/next` entry for SSR + placeholder.
- **Vue/Svelte/vanilla**: use `@splinetool/runtime` directly.
- **three.js interop**: export GLB and load with `GLTFLoader` when you want full code control (drops Spline interactivity).

### React with a loading state
```jsx
import { Suspense } from 'react';
import Spline from '@splinetool/react-spline';
export default function Hero() {
  return (
    <Suspense fallback={<div className="skeleton">Loading 3D…</div>}>
      <Spline
        scene="https://prod.spline.design/YOUR_ID/scene.splinecode"
        onLoad={(spline) => { spline.setVariable('theme', 'dark'); }}
      />
    </Suspense>
  );
}
```

### Export decision guide
| You need… | Export as |
|---|---|
| Full interactivity, states, events | `.splinecode` (Spline runtime) |
| Static geometry in three.js/R3F | **GLB/GLTF** (no runtime dependency) |
| A poster/preview | image/video export |
| Framework code stub | React/vanilla code snippet |

## Best For / Avoid For
`landing-page-3d`, `product-showcases`, `no-code-interactive-3d`, `design-portfolios`, `marketing-3d` — choose Spline when designers own the 3D and you want polished interactive scenes fast.
Avoid for: procedural/code-generated scenes, deep runtime material control, open-source-only stacks, or performance-critical/large 3D apps (use three.js/R3F/PlayCanvas).

## See Also
- `three_js.md`, `react-three-fiber.md` — code-first 3D (Spline GLB exports drop in here)
- `verge3d.md`, `playcanvas.md` — other editor/engine-driven 3D web tools
- `../use-case/3d-graphics.md` — 3D solution selection
