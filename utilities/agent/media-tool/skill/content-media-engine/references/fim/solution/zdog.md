# Zdog — pseudo-3D flat-shaded illustration engine

Zdog is a tiny "pseudo-3D" engine for round, flat-designed vector illustrations rendered on Canvas or SVG. It draws a real 3D scene graph (shapes have `translate.z`, the scene rotates in 3D) but shades everything **flat** — no lighting, no textures, no perspective foreshortening — producing a charming, chunky, designer-friendly look. It's perfect for logos, icons, loaders, and stylized 3D-ish illustrations where you want depth and rotation without a full WebGL engine.

**Current Version**: 1.1.x (npm `zdog`, current major) **License**: MIT **Bundle/Runtime**: ~28 KB min / ~8 KB gz; renders to Canvas or SVG. No dependencies.

## Official Resources & Documentation
- **Site / docs**: https://zzz.dog/
- **API**: https://zzz.dog/api
- **Examples**: https://zzz.dog/#made-with-zdog
- **Repo**: https://github.com/metafizzy/zdog
- **npm**: https://www.npmjs.com/package/zdog

## Installation & Setup

### Package manager
```bash
npm install zdog
```
```javascript
import Zdog from 'zdog';
// or named: import { Illustration, Box, Ellipse, Shape, TAU } from 'zdog';
```

### CDN
```html
<script src="https://unpkg.com/zdog@1/dist/zdog.dist.min.js"></script>
```

## Core Syntax / API Reference

### Illustration — the root/canvas
Everything lives under an `Illustration`, which owns the canvas/SVG element and the render loop.
```javascript
const illo = new Zdog.Illustration({
  element: '.zdog-canvas',   // <canvas> or <svg> selector/element
  zoom: 4,                   // scale factor
  dragRotate: true,          // built-in mouse/touch rotation
  resize: 'fullscreen',      // auto-resize option
  rotate: { x: -0.3, y: 0.5 },
});
```

### Anchors, translate, rotate
Every node is a `Zdog.Anchor` (or subclass) positioned by `translate` and oriented by `rotate` in 3D.
```javascript
translate: { x: 0, y: 0, z: 100 },   // z gives depth
rotate:    { x: 0, y: Zdog.TAU/8, z: 0 },  // TAU = 2π (full turn)
scale:     1.5,
addTo:     illo,                     // parent (illustration or group)
```

### Shapes
```javascript
new Zdog.Shape({ addTo: illo, path: [ {x:0,y:-40}, {x:40,y:40}, {x:-40,y:40} ],
                 closed: true, stroke: 20, color: '#E62', fill: true });   // custom path
new Zdog.Ellipse({ addTo: illo, diameter: 80, stroke: 20, color: '#636' });
new Zdog.Rect({ addTo: illo, width: 80, height: 80, stroke: 8, color: '#EA0', fill: true });
new Zdog.RoundedRect({ addTo: illo, width: 80, height: 60, cornerRadius: 12, stroke: 6 });
new Zdog.Polygon({ addTo: illo, radius: 40, sides: 6, stroke: 6 });        // hexagon
```

### Solid primitives (the "3D" pieces)
```javascript
new Zdog.Box({ addTo: illo, width: 100, height: 100, depth: 100, stroke: false,
  color: '#C25', leftFace: '#EA0', rightFace: '#E62', topFace: '#ED0', bottomFace: '#636' });
new Zdog.Cylinder({ addTo: illo, diameter: 80, length: 100, stroke: false, color: '#636', backface: '#EA0' });
new Zdog.Cone({ addTo: illo, diameter: 70, length: 90, stroke: false, color: '#663' });
new Zdog.Hemisphere({ addTo: illo, diameter: 80, stroke: false, color: '#C25', backface: '#EA0' });
```

### Groups
```javascript
const group = new Zdog.Group({ addTo: illo, translate: { x: 100 } });
new Zdog.Cone({ addTo: group, diameter: 70, length: 90, color: '#663' });
// group transforms apply to all children
```

### Render loop
```javascript
function animate() {
  illo.rotate.y += 0.03;         // spin the whole scene
  illo.updateRenderGraph();      // sort by depth + render (REQUIRED each frame)
  requestAnimationFrame(animate);
}
animate();
```
`updateRenderGraph()` recomputes z-sorting and redraws — you must call it whenever anything changes. For a static scene, call it once.

## Renderers / Output Types
- **Canvas** — `element` is a `<canvas>`; faster for many shapes.
- **SVG** — `element` is an `<svg>`; crisp, DOM-inspectable, exportable, but heavier for many shapes.
- Shape set: Shape (path), Ellipse, Rect, RoundedRect, Polygon, Box, Cylinder, Cone, Hemisphere, Group, Anchor.

## How-To

### How to add colors & flat shading (mandatory styling recipe)
Zdog has **no lighting** — color is set per shape (and per face on solids). "Shading" is achieved by giving each face a different flat color. Colors are any CSS color string.
```javascript
// A cube with hand-picked face colors reads as lit without any light source
const cube = new Zdog.Box({
  addTo: illo, width: 120, height: 120, depth: 120, stroke: false,
  color:      '#C25',   // fallback for any unset face
  frontFace:  '#f25c54',
  rearFace:   '#8a1c2b',
  leftFace:   '#e6773b',  rightFace: '#c84b1e',
  topFace:    '#ffd23f',  bottomFace: '#3a2a4d',
});

// Rounded strokes ARE the fill for flat shapes — stroke width = thickness
new Zdog.Ellipse({ addTo: illo, diameter: 90, translate: { z: 80 },
                   stroke: 24, color: '#4f8cff' });      // fat rounded ring

// Fill a path
new Zdog.Shape({ addTo: illo, path: starPath, closed: true, fill: true, stroke: 4, color: '#FD0' });
```
Technique: pick a palette where "top" faces are lighter and "bottom" faces darker to fake directional light. `stroke` (a number) gives shapes rounded, tube-like thickness — it's central to Zdog's look, not just an outline.

### How to render as SVG instead of Canvas
```javascript
const illoSVG = new Zdog.Illustration({ element: '.zdog-svg', zoom: 4 });
new Zdog.Shape({ addTo: illoSVG, path: [{x:0,y:-40},{x:40,y:40},{x:-40,y:40}],
                 closed: true, stroke: 20, color: '#E62' });
illoSVG.updateRenderGraph();
```

### How to animate with easing (illustration-style loops)
```javascript
let ticker = 0; const cycle = 120;
function animate() {
  const progress = (ticker % cycle) / cycle;
  const eased = Zdog.easeInOut(progress, 3);      // built-in easing
  illo.rotate.y = eased * Zdog.TAU;               // one full turn per cycle
  illo.updateRenderGraph();
  ticker++;
  requestAnimationFrame(animate);
}
animate();
```

### How to let users drag-rotate
```javascript
const illo = new Zdog.Illustration({ element: '.zdog-canvas', zoom: 4, dragRotate: true });
// dragRotate handles pointer input; still call updateRenderGraph in your loop
```

### How to build a compound model (grouped parts)
```javascript
// A simple "robot head": box + two eyes + antenna, moved together as a group
const head = new Zdog.Anchor({ addTo: illo });
new Zdog.Box({ addTo: head, width: 120, height: 120, depth: 120, stroke: false,
  color: '#5b8', topFace: '#7ca', frontFace: '#4a7', bottomFace: '#396' });
[-30, 30].forEach((x) => new Zdog.Ellipse({ addTo: head, diameter: 26, translate: { x, y: -10, z: 61 },
  stroke: 8, color: '#123', fill: true }));
new Zdog.Shape({ addTo: head, path: [{ y: -60 }, { y: -100 }], translate: { z: 20 }, stroke: 6, color: '#fd0' });
new Zdog.Ellipse({ addTo: head, diameter: 12, translate: { y: -100, z: 20 }, stroke: 10, color: '#f33' });
// animate the whole head
(function loop(){ head.rotate.y += 0.02; illo.updateRenderGraph(); requestAnimationFrame(loop); })();
```

### How to draw a curved custom path (arcs & beziers)
```javascript
new Zdog.Shape({
  addTo: illo, closed: false, stroke: 12, color: '#e62',
  path: [
    { x: -60, y: 0 },
    { arc: [ { x: -60, y: -60 }, { x: 0, y: -60 } ] },   // quadratic arc
    { bezier: [ { x: 40, y: -60 }, { x: 60, y: -20 }, { x: 60, y: 40 } ] },  // cubic bezier
  ],
});
```

## Do's and Don'ts

### ✅ Do
- Call `illo.updateRenderGraph()` after any change (and every frame when animating).
- Fake lighting by assigning lighter/darker flat colors to different faces.
- Use `stroke` (a number) to give shapes rounded thickness — it's the signature look.
- Use `Zdog.TAU` (full turn) and `Zdog.easeInOut` for clean rotational loops.
- Group related shapes so one transform moves/rotates them together.

### ❌ Don't
- Don't expect real perspective, lighting, shadows, or textures — Zdog is flat pseudo-3D by design.
- Don't build complex/high-poly models — it's for simple, stylized illustration; many shapes get slow (especially SVG).
- Don't forget `updateRenderGraph()` — nothing updates without it.
- Don't rely on it for accurate 3D or data-driven scenes — use three.js.
- Don't animate hundreds of shapes on SVG — switch to canvas or reduce shape count.

## Styling, Theming & Customization
- **Color**: `color` (per shape) + per-face colors on solids (`leftFace`, `topFace`, `backface`, etc.).
- **Stroke thickness**: numeric `stroke` gives rounded tube thickness; `stroke: false` for flat faces.
- **Fill**: `fill: true` fills closed paths.
- **Zoom/scale**: `illo.zoom` global scale; per-shape `scale`.
- **Backface**: `backface` color (or `false` to hide) controls the reverse side of flat shapes.

## Math & Animation Helpers
```javascript
Zdog.TAU               // 2π — one full turn (use for rotations)
Zdog.lerp(a, b, t)     // linear interpolation
Zdog.easeInOut(t, n)   // eased 0..1 (n = strength/power)
Zdog.modulo(a, b)      // positive modulo (great for looping tickers)
new Zdog.Vector({ x, y, z })   // 3D vector with add/subtract/rotate/multiply
anchor.copyGraph()     // deep-clone a shape/group subtree
anchor.remove()        // detach from parent
```

## Advanced Features
- **Custom paths** with arc/bezier segments: `path: [{x,y}, { arc: [ {x,y}, {x,y} ] }, ...]`.
- **Dragging + inertia** via `dragRotate` and manual rotation math.
- **Easing helpers**: `Zdog.easeInOut`, `Zdog.lerp`, `Zdog.modulo`.
- **Anchor-only nodes** for pivots/attach points without geometry.
- **Depth sorting** handled automatically by `updateRenderGraph`.

## Common Pitfalls & Troubleshooting
- **Nothing renders / static** — `updateRenderGraph()` not called (once for static, every frame for animation).
- **Shapes overlap wrong** — z-sorting is per-shape (painter's algorithm); intersecting geometry can't sort correctly — offset shapes in z.
- **Looks flat/dull** — all faces same color; vary face colors to fake lighting.
- **Slow** — too many shapes, especially in SVG mode; reduce count or use canvas.
- **Blurry on retina** — Zdog handles DPR, but ensure the canvas element isn't CSS-stretched beyond its backing size.
- **Rotation feels off** — angles are radians; use `Zdog.TAU` for a full turn.

## Integration Notes
- Framework-agnostic; in React create the illustration in `useEffect` against a canvas/svg ref and start the loop, cancel RAF on cleanup.
- Pairs with GSAP or manual RAF for choreographed rotations; keep `updateRenderGraph` in the loop.

## Best For / Avoid For
`3d-logos`, `icons-with-depth`, `loaders`, `stylized-illustration`, `retro-3d-ui` — choose Zdog for small, charming pseudo-3D vector art without a WebGL engine.
Avoid for: realistic/lit 3D, textured models, large scenes, data visualization at scale, or anything needing true perspective (use three.js/R3F).

## See Also
- `three_js.md`, `react-three-fiber.md` — real 3D when you outgrow pseudo-3D
- `two_js.md`, `p5_js.md`, `rough_js.md` — 2D drawing / creative coding
- `../use-case/3d-graphics.md` — 3D solution selection
- `../use-case/creative-animation.md` — creative solution selection
