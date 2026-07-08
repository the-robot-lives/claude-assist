# Two.js — renderer-agnostic 2D drawing

Two.js is a lightweight 2D drawing library with one API that renders to **SVG, Canvas, or WebGL** — you pick the backend at construction and your scene-graph code stays the same. It provides shape factories (`makeCircle`, `makeRectangle`, `makePath`), a retained scene graph with groups/transforms, and a built-in animation loop (`two.bind('update')`). It's aimed at flat 2D illustration, generative art, motion graphics, and diagrams — a middle ground between raw Canvas and a heavy engine.

**Current Version**: 0.8.x (npm `two.js`, current major) **License**: MIT **Bundle/Runtime**: ~60 KB gz; renders to SVG/Canvas/WebGL depending on the chosen `type`.

## Official Resources & Documentation
- **Site / docs**: https://two.js.org/
- **API reference**: https://two.js.org/docs/
- **Examples**: https://two.js.org/examples/
- **Repo**: https://github.com/jonobr1/two.js
- **npm**: https://www.npmjs.com/package/two.js

## Installation & Setup

### Package manager
```bash
npm install two.js
```
```javascript
import Two from 'two.js';
```

### CDN
```html
<script src="https://cdn.jsdelivr.net/npm/two.js@latest/build/two.min.js"></script>
```

### Construct + mount
```javascript
const two = new Two({
  type: Two.Types.svg,     // svg (default) | canvas | webgl
  width: 640, height: 480, // OR fullscreen: true / fitted: true
  autostart: true,         // begin the update loop immediately
}).appendTo(document.getElementById('stage'));
```
Choose `svg` for crisp/inspectable output, `canvas` for many shapes / pixel effects, `webgl` for the highest shape counts.

## Core Syntax / API Reference

### Shape factories (added to the scene automatically)
```javascript
two.makeCircle(x, y, radius);
two.makeRectangle(x, y, width, height);
two.makeRoundedRectangle(x, y, width, height, radius);
two.makeEllipse(x, y, rx, ry);
two.makeLine(x1, y1, x2, y2);
two.makeCurve(...points, /* open? */ true);
two.makePath(anchorsArray, /* closed? */ true);
two.makePolygon(x, y, radius, sides);
two.makeStar(x, y, outerRadius, innerRadius, sides);
two.makeArcSegment(x, y, innerR, outerR, startAngle, endAngle);
two.makeText('Hello', x, y);
two.makeGroup(childA, childB);
two.makeLinearGradient(x1, y1, x2, y2, ...stops);
two.makeRadialGradient(x, y, radius, ...stops);
```

### Styling a shape (properties on the returned object)
```javascript
const c = two.makeCircle(70, 100, 50);
c.fill = '#FF8000';          // hex, rgb(a), hsl, named, or a gradient object
c.stroke = 'orangered';
c.linewidth = 5;
c.opacity = 0.8;
c.noStroke();  c.noFill();
c.cap = 'round'; c.join = 'round'; c.dashes = [4, 4];
```

### Transforms & the scene graph
```javascript
c.translation.set(120, 90);   // Two.Vector
c.rotation = Math.PI / 4;     // radians
c.scale = 1.5;                // or a Two.Vector for non-uniform

const group = two.makeGroup(c, rect);
group.translation.set(100, 100);
group.rotation = Math.PI / 6;
group.scale = 0.75;           // transforms apply to all children
group.add(otherShape); group.remove(c);
```

### Custom paths with anchors (Bézier control)
```javascript
const anchors = [
  new Two.Anchor(0, 0),
  new Two.Anchor(60, 40),
  new Two.Anchor(60, 100),
  new Two.Anchor(0, 60),
];
const path = two.makePath(anchors, true);   // closed
path.curved = true;                          // smooth through anchors
path.fill = '#2196F3';
```

### The update loop
```javascript
two.bind('update', (frameCount, timeDelta) => {
  c.rotation += 0.02;
  rect.scale = Math.sin(frameCount * 0.05) * 0.3 + 1;
});
two.play();   // start (if not autostart)
two.pause();
two.update(); // render one frame manually
```
`two.update()` is what flushes scene-graph changes to the renderer; the loop calls it for you.

## Renderers / Output Types
- **SVG** (`Two.Types.svg`) — DOM nodes, crisp at any zoom, CSS/inspectable, exportable.
- **Canvas** (`Two.Types.canvas`) — immediate raster; better for hundreds of shapes / pixel work.
- **WebGL** (`Two.Types.webgl`) — GPU-accelerated for the largest shape counts / particle fields.
- **Interpretation**: import SVG into the scene graph via `two.interpret(svgNode)` / `two.load(url, cb)`.

## How-To

### How to add colors, gradients & strokes (mandatory styling recipe)
Every shape exposes `fill`, `stroke`, `linewidth`, `opacity`. Colors accept any CSS color string; `fill`/`stroke` can also be gradient objects created by the `make*Gradient` factories.
```javascript
// Solid + stroke
const star = two.makeStar(200, 200, 50, 90, 5);
star.fill = 'hsl(45, 100%, 55%)';
star.stroke = '#333'; star.linewidth = 3;

// Linear gradient fill
const grad = two.makeLinearGradient(0, -60, 0, 60,
  new Two.Stop(0, '#4f8cff'),
  new Two.Stop(1, '#ff4f8c'));
const rect = two.makeRectangle(320, 200, 160, 120);
rect.fill = grad;
rect.noStroke();

// Radial glow
const glow = two.makeRadialGradient(0, 0, 80,
  new Two.Stop(0, 'rgba(255,255,255,1)'),
  new Two.Stop(1, 'rgba(255,255,255,0)'));
two.makeCircle(120, 120, 80).fill = glow;

two.update();   // flush style changes to the renderer
```
Gradient coordinates are in the shape's **local** space (centered on the shape's origin). Always `two.update()` (or rely on the loop) after mutating styles.

### How to build a particle system (from the stub, expanded)
```javascript
function particles(two, count) {
  const ps = [];
  for (let i = 0; i < count; i++) {
    const p = two.makeCircle(Math.random() * two.width, Math.random() * two.height, 2);
    p.fill = `hsl(${Math.random() * 360}, 100%, 50%)`;
    p.noStroke();
    p.velocity = new Two.Vector(Math.random() * 2 - 1, Math.random() * 2 - 1);
    ps.push(p);
  }
  two.bind('update', () => ps.forEach(p => {
    p.translation.add(p.velocity);
    if (p.translation.x > two.width)  p.translation.x = 0;
    if (p.translation.y > two.height) p.translation.y = 0;
  }));
  return ps;
}
```

### How to draw text
```javascript
const t = two.makeText('Hello Two.js', 320, 40);
t.size = 28; t.fill = '#222'; t.family = 'Inter, sans-serif';
t.alignment = 'center'; t.weight = 700;
```

### How to import/animate an existing SVG
```javascript
two.load('logo.svg', (group) => {   // returns a Two.Group of the SVG's shapes
  group.translation.set(two.width / 2, two.height / 2);
  two.bind('update', () => group.rotation += 0.005);
});
```

### How to animate Two.js shapes with GSAP (smoother easing)
The built-in `bind('update')` loop is linear; for eased/sequenced motion, tween shape properties with GSAP and let Two.js render.
```javascript
import { gsap } from 'gsap';
const c = two.makeCircle(100, 100, 40); c.fill = '#4f8cff';
gsap.to(c.translation, { x: 500, duration: 2, ease: 'power2.inOut', repeat: -1, yoyo: true });
gsap.to(c, { rotation: Math.PI * 2, duration: 3, ease: 'none', repeat: -1 });
two.bind('update', () => {});   // Two.js still renders each frame; GSAP mutates the props
```

## Shape property reference
| Property | Type | Notes |
|---|---|---|
| `fill` / `stroke` | color/gradient | CSS string or `make*Gradient` object; `'none'` disables |
| `linewidth` | number | stroke thickness |
| `opacity` | 0–1 | overall alpha |
| `translation` | `Two.Vector` | `.set(x,y)` position |
| `rotation` | number | radians |
| `scale` | number/`Two.Vector` | uniform or per-axis |
| `dashes` | array | dash pattern `[on, off]` |
| `cap` / `join` | string | `'round'`, `'butt'`, `'miter'` |
| `visible` | boolean | show/hide |
| `curved` | boolean | smooth a path through its anchors |

## Do's and Don'ts

### ✅ Do
- Pick the renderer by workload: SVG (crisp/few), Canvas (many), WebGL (thousands).
- Call `two.update()` after batch style/geometry changes (or let the update loop handle it).
- Group related shapes so one transform moves them together.
- Reuse shape objects and mutate `translation`/`rotation` in the loop instead of recreating.
- Use `make*Gradient` + `Two.Stop` for gradients rather than CSS.

### ❌ Don't
- Don't create shapes inside `bind('update')` every frame — build once, animate properties.
- Don't expect SVG-level DOM inspection when using the canvas/webgl renderer — there are no DOM nodes.
- Don't forget rotation is radians.
- Don't animate huge shape counts in SVG mode — DOM churn is the bottleneck; switch to canvas/webgl.
- Don't mutate `two.width/height` and expect shapes to reflow — Two.js doesn't do responsive layout for you.

## Styling, Theming & Customization
- **Fill/stroke**: any CSS color, or gradient objects; `opacity`, `dashes`, `cap`, `join`, `linewidth`.
- **Gradients**: `makeLinearGradient` / `makeRadialGradient` with `Two.Stop(offset, color)`.
- **Transforms**: `translation`, `rotation`, `scale` (uniform or `Two.Vector`), `skewX/skewY`.
- **Grouping**: nested `Two.Group`s for hierarchical styling/transform.
- **Effects**: blend via canvas/webgl compositing; masks via `shape.mask`.

## Advanced Features
- **`two.interpret(svgNode)`** / `two.load()` — turn SVG markup into an editable scene graph.
- **Masking**: assign a shape to `target.mask` to clip.
- **Vector export**: read back the SVG for saving (SVG renderer).
- **Effects registry** (`two.makeSprite`, `two.makeImageSequence`) for raster sprites.
- **Frame-accurate control**: `two.frameCount`, manual `two.update()` for offline/record loops.

## Common Pitfalls & Troubleshooting
- **Changes don't appear** — no `two.update()` and no running loop.
- **Blank canvas** — not `appendTo`'d, zero width/height, or `autostart`/`play()` missing.
- **Gradient positioned oddly** — coordinates are local to the shape origin, not global.
- **Slow with many shapes** — SVG renderer DOM overhead; switch to `canvas` or `webgl`.
- **Rotation off** — radians vs degrees.
- **Imported SVG missing styles** — some CSS/filters don't survive `interpret`; inline presentation attributes translate best.

## Integration Notes
- Framework-agnostic; in React construct in `useEffect`, `appendTo` a ref, and `two.pause()`/remove on cleanup.
- Pairs with GSAP (animate shape properties) for richer easing than the raw update loop.

## Best For / Avoid For
`flat-2d-illustration`, `generative-art`, `2d-motion-graphics`, `diagrams`, `svg-canvas-webgl-portability` — choose Two.js when you want one 2D API across renderers with a friendly scene graph.
Avoid for: heavy interactive games (PixiJS), 3D (three.js), complex data charts (a charting lib), or After Effects playback (Lottie).

## See Also
- `p5_js.md`, `pts_js.md` — creative-coding drawing libraries
- `rough_js.md` — hand-drawn 2D styling
- `zdog.md` — pseudo-3D flat illustration
- `gsap.md` — animate Two.js shape properties
- `../use-case/creative-animation.md` — solution selection
