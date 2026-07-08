# Rough.js — hand-drawn, sketchy graphics

Rough.js draws shapes in a deliberately imperfect, hand-sketched style — wobbly strokes, hachure fills, sketchy outlines — on Canvas or SVG. It's a tiny, dependency-free library that turns primitives (rectangle, ellipse, line, polygon, path, arc) and even arbitrary SVG paths into "drawn by hand" versions with controllable roughness. It powers the aesthetic of tools like Excalidraw and is ideal for wireframes, playful charts, diagrams, and illustrations that shouldn't look computer-perfect.

**Current Version**: 4.6.x (npm `roughjs`, current major) **License**: MIT **Bundle/Runtime**: ~9 KB gz; renders to Canvas 2D or SVG (no animation loop of its own).

## Official Resources & Documentation
- **Site**: https://roughjs.com/
- **Repo / wiki (API)**: https://github.com/rough-stuff/rough/wiki
- **npm**: https://www.npmjs.com/package/roughjs
- **Excalidraw** (built on it): https://excalidraw.com/

## Installation & Setup

### Package manager
```bash
npm install roughjs
```
```javascript
import rough from 'roughjs';
```

### CDN
```html
<script src="https://cdn.jsdelivr.net/npm/roughjs@4/bundled/rough.js"></script>
```

### Create a renderer
```javascript
const rc = rough.canvas(document.getElementById('canvas'));   // Canvas 2D
// or SVG:
const svg = document.getElementById('svg');
const rcSvg = rough.svg(svg);
// or a generator (produces drawables you render yourself):
const gen = rough.generator();
```

## Core Syntax / API Reference

### Canvas API (`rough.canvas`) — draws immediately
```javascript
rc.line(x1, y1, x2, y2, options);
rc.rectangle(x, y, width, height, options);
rc.circle(centerX, centerY, diameter, options);
rc.ellipse(centerX, centerY, width, height, options);
rc.polygon([[x1,y1],[x2,y2],[x3,y3]], options);
rc.linearPath([[x1,y1],[x2,y2],...], options);   // open connected line
rc.arc(x, y, width, height, start, stop, closed, options);   // angles in radians
rc.curve([[x1,y1],[x2,y2],...], options);        // smooth curve through points
rc.path('M10 10 L90 10 L90 90 Z', options);      // any SVG path data
```

### SVG API (`rough.svg`) — returns a `<g>` node you append
```javascript
const node = rcSvg.rectangle(10, 10, 200, 100, { fill: 'red', fillStyle: 'hachure' });
svg.appendChild(node);
```

### Generator API (draw later / reuse)
```javascript
const gen = rough.generator();
const rect = gen.rectangle(10, 10, 100, 100, { roughness: 2 });
const circle = gen.circle(60, 60, 80);
rc.draw(rect);        // render a drawable onto a rough.canvas
rc.draw(circle);
// same seed → same wobble each render (see options.seed)
```

### Options object (the styling surface)
```javascript
const options = {
  // Stroke
  stroke: 'blue',            // outline color (or 'none')
  strokeWidth: 2,
  // Fill
  fill: 'red',               // fill color
  fillStyle: 'hachure',      // hachure | solid | zigzag | cross-hatch | dots | dashed | zigzag-line
  fillWeight: 3,             // thickness of fill lines
  hachureAngle: 60,          // angle of hachure lines (deg)
  hachureGap: 8,             // gap between hachure lines
  // Sketchiness
  roughness: 1.5,            // 0 = precise, higher = sketchier (typical 0–3)
  bowing: 1,                 // how much lines bow/curve
  seed: 42,                  // fix randomness for reproducible output
  // Curve/precision
  curveStepCount: 9,
  disableMultiStroke: false, // single vs double sketch stroke
  preserveVertices: false,
};
```

## Fill Styles / Output Types
- **fillStyle** options: `hachure` (default parallel lines), `solid`, `zigzag`, `cross-hatch`, `dots`, `dashed`, `zigzag-line`.
- **Renderers**: Canvas 2D (immediate) and SVG (returns nodes). Generator produces backend-agnostic drawables.
- **Shapes**: line, rectangle, circle, ellipse, polygon, linearPath, arc, curve, path (arbitrary SVG `d`).

## How-To

### How to add colors & fill styles (mandatory styling recipe)
Color and texture come from the options object: `stroke` for the outline, `fill` + `fillStyle` for the interior sketchy fill. Colors are any CSS color string.
```javascript
// Sketchy filled card with cross-hatch and a colored wobbly border
rc.rectangle(20, 20, 220, 120, {
  fill: 'rgba(79, 140, 255, 0.35)',
  fillStyle: 'cross-hatch',
  fillWeight: 2,
  hachureAngle: 35,
  hachureGap: 6,
  stroke: '#2456b0',
  strokeWidth: 2,
  roughness: 1.8,
  bowing: 1.2,
  seed: 7,             // reproducible wobble
});

// Dotted fill circle
rc.circle(320, 90, 120, { fill: '#22c55e', fillStyle: 'dots', stroke: '#0f5132' });

// Solid fill (still sketchy edges)
rc.ellipse(120, 220, 180, 90, { fill: '#ffcc00', fillStyle: 'solid', stroke: 'black' });
```
Set a fixed `seed` when you re-render (e.g. on resize) so the sketch doesn't "reshuffle" each frame. Higher `roughness`/`bowing` = more hand-drawn; `hachureAngle`/`hachureGap`/`fillWeight` tune the fill texture.

### How to draw a sketchy bar chart
```javascript
function sketchyBars(canvas, data) {
  const rc = rough.canvas(canvas);
  const bw = canvas.width / data.length;
  data.forEach((v, i) => {
    rc.rectangle(i * bw + 10, canvas.height - v, bw - 20, v, {
      fill: `hsl(${i * 40}, 70%, 55%)`, fillStyle: 'hachure', roughness: 1.5, seed: i + 1,
    });
  });
}
```

### How to render into SVG (for export/DOM)
```javascript
const rcSvg = rough.svg(document.getElementById('svg'));
const g = rcSvg.path('M10 10 L90 10 L90 90 Q50 90 10 50 Z',
                     { fill: 'blue', fillStyle: 'zigzag', stroke: 'black' });
document.getElementById('svg').appendChild(g);
```

### How to keep sketch stable across redraws
```javascript
const opts = { roughness: 2, seed: 1234 };   // same seed → identical wobble
function redraw() { rc.rectangle(10, 10, 200, 100, opts); }
addEventListener('resize', redraw);
```

### How to animate a sketchy shape WITHOUT the wobble boiling
Fix the seed so the sketch stays stable, and animate only position/size by clearing + redrawing.
```javascript
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');
const rc = rough.canvas(canvas);
let t = 0;
(function loop() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);      // clear each frame
  const x = 100 + Math.sin(t) * 80;
  rc.circle(x, 150, 100, { fill: '#4f8cff', fillStyle: 'hachure', roughness: 1.5, seed: 99 }); // fixed seed
  t += 0.03;
  requestAnimationFrame(loop);
})();
```

### How to sketch-ify an arbitrary SVG icon and export it
```javascript
const rcSvg = rough.svg(document.getElementById('out'));
// pass any SVG path 'd' string (e.g. an icon) to get a hand-drawn version:
const node = rcSvg.path('M12 2 L2 22 L22 22 Z', { fill: '#22c55e', fillStyle: 'zigzag', roughness: 2 });
document.getElementById('out').appendChild(node);   // now serializable via outerHTML for export
```

## Do's and Don'ts

### ✅ Do
- Set an explicit `seed` when you'll redraw the same shape, so the wobble is stable.
- Choose `fillStyle` to match the vibe (`hachure`/`cross-hatch` = pencil, `dots` = stipple, `solid` = filled-but-sketchy).
- Use `rough.svg` when you need exportable/DOM output; `rough.canvas` for speed.
- Use the generator API to precompute drawables you render repeatedly.
- Tune `roughness` + `bowing` together for the hand-drawn feel.

### ❌ Don't
- Don't animate Rough.js by redrawing every frame with a random seed — it flickers wildly; fix the seed or don't animate the wobble.
- Don't expect an update loop, event handling, or scene graph — Rough.js only draws; you manage state.
- Don't use it for precise/technical diagrams where exactness matters — the whole point is imperfection.
- Don't forget to clear the canvas (`ctx.clearRect`) before redrawing — Rough.js draws additively.
- Don't pass thousands of hachure-filled shapes to canvas expecting high FPS — fills are line-heavy.

## Styling, Theming & Customization
- **Sketchiness**: `roughness`, `bowing`, `disableMultiStroke`, `preserveVertices`.
- **Fill texture**: `fillStyle`, `fillWeight`, `hachureAngle`, `hachureGap`.
- **Stroke**: `stroke`, `strokeWidth`, `strokeLineDash`.
- **Reproducibility**: `seed` (integer) locks the random offsets.
- **Colors**: any CSS color for `stroke`/`fill`; combine with `hsl()` for generated palettes.

## Advanced Features
- **Arbitrary SVG paths** via `path()` — sketch-ify any vector artwork or icon.
- **Generator + `draw()`** for backend-agnostic, cacheable drawables.
- **Deterministic output** via `seed` for snapshot-stable rendering.
- **Combine with Canvas/SVG directly** — Rough.js output coexists with normal drawing on the same surface.

## Common Pitfalls & Troubleshooting
- **Flickering "boiling" lines** — redrawing with random seed each frame; set a fixed `seed`.
- **Shapes stack/smear** — canvas not cleared between redraws.
- **Fill missing** — no `fill` set, or `fillStyle` mismatched; `fill:'none'` disables it.
- **Arc looks wrong** — angles are radians and `closed` flag controls pie vs arc.
- **Slow render** — many hachure/cross-hatch fills; reduce fill density or use `solid`.
- **SVG output not visible** — forgot to `appendChild` the returned node.

## Integration Notes
- Pairs with any Canvas/SVG workflow; Excalidraw is the reference integration.
- For animation, combine with GSAP/requestAnimationFrame but animate transforms/positions with a **fixed seed**, not the roughness.
- Framework-agnostic; call inside `useEffect`/`onMounted` after the canvas/SVG mounts.

## Best For / Avoid For
`wireframes`, `sketchy-diagrams`, `playful-charts`, `hand-drawn-illustration`, `excalidraw-style-ui` — choose Rough.js when the imperfect, human look is the point.
Avoid for: precise technical drawings, animated wobble (flickers), interactive scenes needing a scene graph (Two.js/Pixi), or 3D.

## See Also
- `two_js.md`, `p5_js.md`, `pts_js.md` — general 2D drawing / creative coding
- `zdog.md` — flat pseudo-3D illustration
- `../use-case/creative-animation.md` — creative solution selection
- `../use-case/diagram-generation.md` — diagram/sketch use cases
