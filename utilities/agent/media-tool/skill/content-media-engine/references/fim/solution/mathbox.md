# MathBox — 3D Mathematical Visualization (WebGL)

MathBox is a WebGL library (built on Three.js) for presentation-quality **animated 2D/3D
mathematical graphics** — surfaces, vector fields, parametric curves, and data plots, with
smooth transitions ideal for explanatory/teaching visuals. It uses a declarative,
tree-structured API: you attach *view* nodes (cartesian/polar/spherical), *data* nodes
(intervals, areas, arrays), and *display* nodes (line, surface, point, vector) that
reference the data. Choose it for beautiful mathematical animation, not general charting.

**Current Version**: 2.3.x (mathbox2)  **License**: MIT
**Runtime**: Browser WebGL, requires Three.js  **Dependency**: Three.js (version-matched to the bundle)

## Official Resources & Documentation
- GitHub: https://github.com/unconed/mathbox
- Examples: https://mathbox.org/ , https://unconed.github.io/mathbox/
- API notes: https://github.com/unconed/mathbox/blob/master/README.md
- Author talks (context): "Making things with MathBox" by Steven Wittens

## Installation & Setup

### CDN (bundle includes Three.js pairing)
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/mathbox@2.3.1/build/mathbox-bundle.js"></script>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/mathbox@2.3.1/build/mathbox.css">
```
The `mathbox-bundle.js` ships its own compatible Three.js; mixing an incompatible external
Three.js version is the most common breakage. Match versions carefully.

### Package manager
```bash
npm install mathbox three
```

## Core API Reference

MathBox builds a **scene graph** by chaining node factories. The root is a `mathBox({...})`;
you add a `camera`, a coordinate `view` (cartesian/polar/spherical), then `data` and
`display` primitives. Display nodes read the nearest preceding data node.

### Initialize + camera + view
```javascript
const mathbox = MathBox.mathBox({
  plugins: ['core', 'controls', 'cursor'],
  controls: { klass: THREE.OrbitControls },
});
mathbox.three.renderer.setClearColor(new THREE.Color(0xffffff), 1.0);

mathbox.camera({ proxy: true, position: [2, 1, 2] });

const view = mathbox.cartesian({
  range: [[-2, 2], [-2, 2], [-2, 2]],   // x, y, z data ranges
  scale: [2, 2, 1],                     // aspect of the unit box
});
```

### Axes & grid
```javascript
view.axis({ axis: 1, color: '#e74c3c' })   // x
    .axis({ axis: 2, color: '#2ecc71' })   // y
    .axis({ axis: 3, color: '#3498db' });  // z
view.grid({ axes: [1, 3], divideX: 10, divideY: 10, color: '#bbb' });
```

### Data primitives
```javascript
// interval: 1D sampling → a line/curve
view.interval({ width: 256, expr: (emit, x, i, t) => emit(x, Math.sin(x + t)) });

// area: 2D grid → a surface
view.area({
  width: 64, height: 64, axes: [1, 3],
  expr: (emit, x, y, i, j, t) => emit(x, Math.sin(x) * Math.cos(y), y),
});

// array: explicit points
view.array({ width: 4, items: 1, channels: 3, data: [[0,0,0],[1,1,0],[1,0,1],[0,1,1]] });
```
`emit(...)` outputs a point's coordinates; `t` is elapsed time (enables animation for free).

### Display primitives (consume the preceding data)
```javascript
view.interval({ width: 256, expr: (emit, x, i, t) => emit(x, Math.cos(x + t)) })
    .line({ color: '#8e44ad', width: 4 });

view.area({ width: 64, height: 64, axes: [1,3],
    expr: (emit, x, y) => emit(x, Math.sin(x)*Math.cos(y), y) })
    .surface({ shaded: true, color: '#4080ff', opacity: 0.9 });

view.point({ color: '#e67e22', size: 8 });
view.vector({ color: '#c0392b', width: 3, end: true });
```

### Animation: clocks & play
```javascript
const clock = mathbox.clock({ speed: 1 });     // drives `t` in exprs
// Or explicitly tween a property:
view.play({ target: 'camera', from: { position: [2,1,2] }, to: { position: [0,3,0] }, duration: 4 });
```

## Primitive Types Overview
- **Views**: `cartesian`, `polar`, `spherical`, `cartesian4` (for projections).
- **Data**: `interval` (1D), `area` (2D grid), `array`/`matrix`/`volume` (explicit), `scale`, `lerp`.
- **Display**: `line`, `surface`, `point`, `vector`, `face`, `strip`, `ticks`, `label`, `text`.
- **Structure**: `group`, `transform`/`transform4`, `reveal`, `slide`, `clock`, `play`.

## How-To (worked recipes)

### How to color and shade a surface
Color via hex; enable `shaded` for lighting; per-vertex color via a color data channel.
```javascript
view.area({ width: 64, height: 64, axes: [1, 3],
  expr: (emit, x, y) => emit(x, 0.5*Math.sin(2*x)*Math.cos(2*y), y) });
view.surface({ shaded: true, color: '#2980b9', opacity: 0.85, lineX: true, lineY: true });
```

### How to plot an animated parametric helix
```javascript
view.interval({
  width: 256,
  expr: (emit, x, i, t) => {
    const theta = x * 4 * Math.PI + t;      // t animates the whole curve
    emit(Math.cos(theta), x * 2 - 1, Math.sin(theta));
  },
}).line({ color: '#ff4080', width: 3 });
```

### How to draw a vector field
```javascript
view.area({ width: 12, height: 12, axes: [1, 3],
  expr: (emit, x, y) => { emit(x, 0, y); emit(x + 0.3*Math.sin(y), 0.4, y + 0.3*Math.cos(x)); },
  items: 2, channels: 3,
}).vector({ color: '#16a085', width: 2, end: true });
```

### How to animate a camera fly-through
```javascript
mathbox.play({
  target: 'camera',
  from: { position: [3, 1, 3] },
  to:   { position: [0, 4, 0] },
  pace: 5, loop: true,
});
```

## Do's and Don'ts

### ✅ Do
- Use the `mathbox-bundle.js` and its matched Three.js version — mismatches are the top failure.
- Structure scenes as view → data → display; display nodes read the nearest preceding data.
- Animate for free by using the `t` argument in `expr` callbacks (driven by a `clock`).
- Set `range` and `scale` on the view to frame and proportion the space.
- Reuse `group`/`transform` nodes to move/reveal subtrees rather than rebuilding data.

### ❌ Don't
- Don't pull in an unrelated Three.js build alongside the bundle — pick one compatible Three.js.
- Don't over-sample surfaces (`width`/`height` in the hundreds²) — WebGL vertex counts explode.
- Don't expect chart axes/legends/tooltips — MathBox is math-graphics, not a charting library.
- Don't forget `OrbitControls` (via the `controls` plugin) if you want mouse interaction.
- Don't compute heavy math per-frame on the CPU for large grids — keep `expr` cheap.

## Styling, Theming & Customization
- **Color**: `color` on any display node (hex/CSS); per-vertex color via a color data channel.
- **Surfaces**: `shaded`, `opacity`, `lineX`/`lineY` (wireframe overlay), `fill`.
- **Lines/points**: `width`, `size`, `depth`, `zBias` (layering), `blending`.
- **Background**: `renderer.setClearColor(...)`.
- **Labels/text**: `label`/`text` nodes with `format`, `size`, `color`.

## Advanced Features
- **Transitions/reveal**: `reveal`, `slide`, and `play` animate presence and properties for storytelling.
- **Multiple coordinate systems** (`polar`, `spherical`) and 4D→3D projection (`cartesian4`, `transform4`).
- **GPU-side sampling** of `expr` for smooth large plots.
- **Compose with raw Three.js** via `mathbox.three` (scene, camera, renderer) for custom meshes/shaders.
- **Presentation stepping** for slide-like math explanations.

## Common Pitfalls & Troubleshooting
- **Blank canvas / errors** → Three.js version mismatch with the bundle.
- **No mouse orbit** → missing `controls` plugin or `OrbitControls` class.
- **Choppy performance** → grid too dense or heavy per-sample math; reduce `width`/`height`.
- **Surface invisible** → wrong `axes` mapping on the data node, or camera inside the geometry.
- **Nothing animates** → `expr` ignores `t`, or no `clock` driving time.

## Framework Integration

### React mount pattern
```jsx
import { useEffect, useRef } from 'react';

function MathBoxScene({ build }) {                 // build(mathbox) constructs the graph
  const hostRef = useRef(null);
  useEffect(() => {
    const mathbox = MathBox.mathBox({
      plugins: ['core', 'controls', 'cursor'],
      controls: { klass: THREE.OrbitControls },
      element: hostRef.current,
    });
    build?.(mathbox);
    return () => { mathbox.select('*').remove(); };  // tear down nodes on unmount
  }, [build]);
  return <div ref={hostRef} style={{ width: '100%', height: 500 }} />;
}
```
Ensure the bundle's matched Three.js is loaded globally before the component mounts.

### How to overlay a typeset equation on the canvas
Position an absolutely-placed [katex](katex.md)/[mathjax](mathjax.md) element over the MathBox
container (MathBox draws WebGL; equation text sits in a sibling DOM layer).
```html
<div style="position:relative">
  <div id="mb" style="width:600px;height:400px"></div>
  <div id="eq" style="position:absolute;top:8px;left:8px"></div>
</div>
<script>katex.render('z = \\sin x \\cos y', document.getElementById('eq'));</script>
```

## Integration Notes
- Built on **Three.js**; anything Three can do (custom shaders, meshes, lights) can join a MathBox scene via `mathbox.three`.
- Pair with [katex](katex.md)/[mathjax](mathjax.md) for typeset equations overlaid on/around the canvas.
- For interactive 2D geometry/algebra instead of 3D graphics, use [jsxgraph](jsxgraph.md)/[geogebra-api](geogebra-api.md).

## Best For / Avoid For
`3d-math`, `surfaces`, `vector-fields`, `animated-explanations`, `parametric`, `teaching-visuals`,
`presentation` — choose MathBox for beautiful animated mathematical 3D.
Avoid for: business/data charts (use a chart library), 2D geometry constructions
([jsxgraph](jsxgraph.md)/[geogebra-api](geogebra-api.md)), or simple 2D function plots
([desmos-api](desmos-api.md)).

## See Also
- [geogebra-api](geogebra-api.md) — dynamic math incl. 3D, higher-level
- [jsxgraph](jsxgraph.md) — 2D interactive geometry/plots
- [desmos-api](desmos-api.md) — 2D graphing calculator
- [katex](katex.md) / [mathjax](mathjax.md) — typeset equations around the scene
- Use case: [../use-case/mathematical-scientific.md](../use-case/mathematical-scientific.md)
