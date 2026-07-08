# Pts.js — point-based creative coding & visualization

Pts.js is a creative-coding library built around a single unifying idea: everything is a **point** (`Pt`), and groups of points (`Group`) compose into lines, curves, shapes, and geometry. It provides expressive vector math, geometry operators (`Line`, `Circle`, `Rectangle`, `Curve`, `Polygon`, `Triangle`), color utilities, sound/DOM inputs, and a `Space`/`Form` rendering model for Canvas, SVG, or HTML. It's a modern, well-typed alternative to p5.js aimed at generative visualization, interactive art, and geometric experiments.

**Current Version**: 0.12.x+ (npm `pts`, current major) **License**: Apache-2.0 **Bundle/Runtime**: ~80 KB gz; renders to Canvas (`CanvasSpace`), SVG (`SVGSpace`), or HTML (`HTMLSpace`). Written in TypeScript.

## Official Resources & Documentation
- **Site / guides**: https://ptsjs.org/
- **API docs**: https://ptsjs.org/docs/
- **Demos**: https://ptsjs.org/demo/
- **Repo**: https://github.com/williamngan/pts
- **npm**: https://www.npmjs.com/package/pts

## Installation & Setup

### Package manager
```bash
npm install pts
```
```javascript
import { CanvasSpace, Pt, Group, Circle, Line, Rectangle, Curve, Const } from 'pts';
// or grab everything onto a namespace: import { Pts } from 'pts'; Pts.namespace(window);
```

### CDN
```html
<script src="https://unpkg.com/pts/dist/pts.min.js"></script>
<script>Pts.namespace(window);</script>   <!-- exposes Pt, Group, CanvasSpace, ... globally -->
```

## Core Syntax / API Reference

### Space → Form → animate (the render model)
A `Space` binds to a canvas/DOM element; its `Form` is the drawing context; you register a "player" object with lifecycle callbacks.
```javascript
const space = new CanvasSpace('#canvas').setup({ bgcolor: '#0b0b12', resize: true, retina: true });
const form = space.getForm();

space.add({
  start: (bound, space) => { /* init once; bound is the play area rectangle */ },
  animate: (time, ftime) => {            // per-frame: time = elapsed ms, ftime = frame delta ms
    const c = Circle.fromCenter(space.pointer, 50);
    form.fillOnly('#fff').circle(c);
  },
  action: (type, x, y, evt) => { /* 'move' | 'down' | 'up' | 'click' | 'drag' ... */ },
  resize: (bound, evt) => {},
});
space.play();                            // start loop (space.playOnce(0) for one frame)
```

### Pt — the point/vector
```javascript
const p = new Pt(100, 50);          // 2D (also 3D+: new Pt(x, y, z))
p.add(10, -5);  p.subtract(other);  p.multiply(2);  p.divide(2);
p.magnitude();  p.unit();  p.angle();  p.rotate2D(Const.quarter_pi);
p.$add(1, 1);                       // '$'-prefixed = non-mutating (returns a new Pt)
Pt.make(3, 0);                      // fill a Pt of given dimensions
space.pointer;                      // current pointer position as a Pt
space.center; space.size;           // Pts describing the space
```

### Group — an array of Pts (lines, shapes, paths)
```javascript
const g = Group.fromArray([[0,0], [50,80], [100,0]]);
g.moveBy(10, 10);  g.rotate2D(0.2, space.center);  g.scale(1.5, space.center);
g.centroid();  g.boundingBox();
const line = Group.fromPtArray([space.center, space.pointer]);
```

### Geometry operators (static classes)
```javascript
Line.collinear(p1, p2, p3);  Line.intersectLine2D(lnA, lnB);  Line.subpoints(group, num);
Circle.fromCenter(center, radius);  Circle.intersectCircle2D(cA, cB);
Rectangle.fromCenter(center, size);  Rectangle.corners(rect);
Curve.bezier(anchors);  Curve.catmullRom(anchors);  Curve.cardinal(anchors);
Polygon.fromCenter(center, radius, sides);  Triangle.fromCenter(center, size);
Geom.interpolate(a, b, t);  Geom.boundAngle(deg);  Num.mapToRange(v, a, b, c, d);
```

### Form — drawing & styling
```javascript
form.fill('#f06').stroke('#fff', 2).rect(rectGroup);
form.fillOnly('#0ff').circle(circle);
form.strokeOnly('#0ff', 2).line(ptGroup);
form.point(pt, radius, 'circle');            // 'circle' | 'square'
form.points(group, radius, 'circle');
form.polygon(group);  form.rect(group);  form.circle(circleGroup);
form.text(pt, 'label');  form.font(14, 'bold');
form.alpha(0.5);  form.composite('lighter');  // canvas compositing
```

## Rendering Spaces / Output Types
- **`CanvasSpace`** — Canvas 2D; the default, fastest for many points.
- **`SVGSpace`** — SVG output (DOM nodes, crisp/exportable).
- **`HTMLSpace`** — position HTML elements as points.
- **Sound / input**: `Sound` (Web Audio FFT/time-domain), `Space` pointer/multitouch, `CanvasForm` compositing.

## How-To

### How to add colors & style (mandatory styling recipe)
Styling is chained on the `Form`: `.fill()`, `.stroke()`, `.fillOnly()`, `.strokeOnly()`, `.alpha()`, plus Pts' `Color` utilities for palettes and interpolation. Colors are CSS strings or `Color` objects.
```javascript
import { CanvasSpace, Circle, Color, Num } from 'pts';
const space = new CanvasSpace('#canvas').setup({ bgcolor: '#0b0b12', retina: true });
const form = space.getForm();

const from = Color.fromHex('#4f8cff');
const to   = Color.fromHex('#ff4f8c');

space.add((time) => {
  space.clear();
  for (let i = 0; i < 40; i++) {
    const t = i / 40;
    const col = Color.LERP(from, to, t);            // interpolate across the palette
    const r = 20 + 60 * Math.sin(time * 0.001 + i * 0.3);
    const c = Circle.fromCenter(space.center.$add(Math.cos(i) * i * 6, Math.sin(i) * i * 6), Math.abs(r));
    form.fillOnly(col.rgba).circle(c);              // .rgba / .hex string
  }
});
space.play();
```
Use `Color.fromHex/rgb/hsl`, `Color.LERP(a, b, t)` for gradients, and HSL space for generative hue cycling. Chain `.alpha()` and `.composite('lighter')` for additive glow.

### How to draw a flowing wave (points → line)
```javascript
const form = space.getForm();
space.add((time) => {
  const pts = [];
  for (let x = 0; x < space.size.x; x += 10) {
    const y = space.center.y + Math.sin(x * 0.02 + time * 0.001) * 100;
    pts.push(new Pt(x, y));
  }
  form.strokeOnly('#0ff', 2).line(Group.fromPtArray(pts));
});
```

### How to make a particle field
```javascript
space.add({
  start: (bound) => { this.pts = Group.fromArray(
      Array.from({ length: 200 }, () => [Math.random()*bound.width, Math.random()*bound.height])); },
  animate: (time, ftime) => {
    this.pts.forEach(p => p.add((Math.random()-0.5)*ftime*0.1, (Math.random()-0.5)*ftime*0.1));
    form.fillOnly('#ff0').points(this.pts, 2, 'circle');
  },
});
```

### How to handle interaction
```javascript
space.add({
  animate: (t) => form.fillOnly('#fff').circle(Circle.fromCenter(space.pointer, 30)),
  action: (type, x, y) => { if (type === 'down') console.log('tap at', x, y); },
});
space.bindMouse().bindTouch();   // enable pointer/touch events
```

### How to build a Delaunay / Voronoi mesh
```javascript
import { CanvasSpace, Group, Delaunay } from 'pts';
const space = new CanvasSpace('#canvas').setup({ bgcolor: '#0b0b12' });
const form = space.getForm();
const pts = Group.fromArray(Array.from({ length: 40 }, () =>
  [Math.random() * space.width, Math.random() * space.height]));

space.add(() => {
  const del = Delaunay.from(pts);
  form.strokeOnly('#09f', 1).polygons(del.delaunay());   // triangulation
  form.strokeOnly('#f39', 0.5).polygons(del.voronoi());  // dual Voronoi cells
});
space.play();
```

### How to draw a phyllotaxis spiral (generative geometry)
```javascript
const form = space.getForm();
space.add((time) => {
  space.clear();
  const c = space.center;
  for (let i = 0; i < 500; i++) {
    const angle = i * 2.399963;                    // golden angle (radians)
    const r = Math.sqrt(i) * 8;
    const p = c.clone().toAngle(angle + time * 0.0002, r, true);
    form.fillOnly(`hsl(${(i * 0.8) % 360}, 80%, 60%)`).point(p, 3, 'circle');
  }
});
```

## Do's and Don'ts

### ✅ Do
- Think in points and groups — build geometry with `Line`/`Circle`/`Curve`/`Polygon` operators.
- Use `$`-prefixed methods (`$add`, `$multiply`) when you need a new Pt instead of mutating.
- Use `space.pointer`, `space.center`, `space.size` (all Pts) instead of tracking coordinates manually.
- Use `Color.LERP` and HSL for palettes; chain Form styling calls.
- Call `space.bindMouse().bindTouch()` to enable input.

### ❌ Don't
- Don't forget `space.play()` — the loop won't run otherwise.
- Don't mutate a Pt when you meant to copy (use `.clone()` or `$` methods) — subtle bugs otherwise.
- Don't recreate large Groups every frame if you can mutate in place.
- Don't expect a huge plugin ecosystem like p5 — Pts is focused and math-forward.
- Don't use SVGSpace for thousands of points — canvas is far faster.

## Styling, Theming & Customization
- **Form styling**: `.fill`, `.stroke`, `.fillOnly`, `.strokeOnly`, `.alpha`, `.composite`, `.font`.
- **Color**: `Color.fromHex/rgb/hsl/lab/lch`, `Color.LERP`, `.rgba`/`.hex`, color-space conversions.
- **Compositing**: canvas globalCompositeOperation via `form.composite('lighter'|'multiply'|...)`.
- **Background/retina**: `space.setup({ bgcolor, retina, resize })`.

## Advanced Features
- **Geometry ops**: intersections, projections, convex hull, Delaunay/Voronoi (via `Delaunay` op), subpoints, tangents.
- **Curves**: Bézier, Catmull-Rom, Cardinal, B-spline through control groups.
- **Sound**: `Sound.load`/`from` + FFT/time-domain arrays → audio-reactive visuals.
- **Typed & tree-shakeable** (TypeScript); import only the ops you use.
- **Multiple spaces / SVG export**.

## Common Pitfalls & Troubleshooting
- **Nothing draws** — `space.play()` missing, or drawing outside the `animate` callback.
- **Sluggish** — recreating Groups each frame or using SVGSpace with many points; mutate in place / use canvas.
- **Points drift/NaN** — mutated a shared Pt; clone or use `$` methods.
- **Input dead** — forgot `bindMouse()/bindTouch()`.
- **Blurry on retina** — enable `retina: true` in setup.
- **`Delaunay`/ops undefined** — not imported; Pts is modular.

## Integration Notes
- TypeScript-first; excellent types for editor autocomplete.
- Framework-agnostic; in React construct the space in `useEffect`, `space.dispose()`/stop on cleanup.
- Pairs with Web Audio for audio-reactive pieces.

## Best For / Avoid For
`generative-art`, `geometric-visualization`, `interactive-art`, `data-art`, `audio-reactive-visuals` — choose Pts.js for point/geometry-centric creative coding with strong math and clean TypeScript.
Avoid for: production charts/dashboards (charting libs), 3D scenes (three.js), or teams wanting p5's larger tutorial ecosystem.

## See Also
- `p5_js.md`, `processing_js.md` — other creative-coding libraries
- `two_js.md` — renderer-agnostic 2D drawing
- `d3-force.md` (../ charts set) — data-driven geometry
- `../use-case/creative-animation.md` — creative solution selection
