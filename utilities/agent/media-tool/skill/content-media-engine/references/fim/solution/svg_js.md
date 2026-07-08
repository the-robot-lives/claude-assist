# SVG.js — Lightweight SVG DOM Drawing & Animation

SVG.js is a small, dependency-free library for **building, manipulating, and animating SVG** through a fluent JavaScript API. Unlike immediate-mode canvas, SVG.js produces retained DOM nodes: every shape is a real `<rect>`/`<circle>`/`<path>` you can style with CSS, attach events to, hit-test, and animate declaratively. It's ideal for interactive diagrams, icons, generative art, and data-driven vector graphics where scalability and DOM interactivity matter. Compared with D3, it's lighter and drawing-focused rather than data-join-focused.

**Current Version**: @svgdotjs/svg.js@3.2.x (current major)  **License**: MIT  **Runtime**: browsers; Node via `svgdom` for headless generation.

## Official Resources & Documentation
- Docs: https://svgjs.dev/docs/3.2/
- Home: https://svgjs.dev/
- GitHub: https://github.com/svgdotjs/svg.js
- npm: https://www.npmjs.com/package/@svgdotjs/svg.js

## Installation & Setup

### Package manager / CDN
```bash
npm install @svgdotjs/svg.js
```
```html
<script src="https://cdn.jsdelivr.net/npm/@svgdotjs/svg.js@3.2/dist/svg.min.js"></script>
```

### Import styles
```javascript
import { SVG } from '@svgdotjs/svg.js';       // ESM
const { SVG } = require('@svgdotjs/svg.js');   // CJS
const draw = SVG().addTo('#drawing').size(400, 400);   // create a root <svg>
const draw2 = SVG('#existing-svg');            // wrap an existing element
```

## Core API Reference

### Shapes
```javascript
draw.rect(120, 80).move(20, 20).radius(8);
draw.circle(80).center(200, 200);              // circle(diameter)
draw.ellipse(160, 90).move(20, 120);
draw.line(0, 0, 200, 200).stroke({ width: 2, color: '#333' });
draw.polyline([[0,0],[50,25],[100,0],[150,25]]);
draw.polygon('50,0 61,35 98,35 68,57 79,91 50,70 21,91 32,57 2,35 39,35'); // star
draw.path('M 10 10 C 20 20, 40 20, 50 10 Z');
draw.image('photo.jpg').size(200, 150);
```

### Positioning & sizing
```javascript
el.move(x, y);          // top-left
el.center(cx, cy);      // by centre
el.size(w, h);
el.dx(10).dy(-5);       // relative shift
el.x(50); el.y(60);     // individual coords
```

### Fill, stroke, styling
```javascript
rect.fill('#f06');
rect.fill({ color: '#06f', opacity: 0.6 });
rect.stroke({ color: '#000', width: 2, linecap: 'round', dasharray: '4 2' });
rect.opacity(0.8);
rect.attr({ rx: 6, 'fill-rule': 'evenodd' });     // any raw SVG attribute
rect.css({ cursor: 'pointer' });                   // inline CSS
rect.addClass('node').removeClass('hidden');       // CSS classes for external styling
```

### Text
```javascript
const t = draw.text('SVG.js').font({ family: 'Inter', size: 42, anchor: 'middle', weight: 'bold' });
t.move(200, 100).fill('#222');
draw.text(add => {                                 // multi-line via tspans
  add.tspan('Line one').newLine();
  add.tspan('Line two').fill('#f06').newLine();
});
draw.text('Curved').path('M 20 100 C 100 0, 200 200, 280 100'); // text on a path
```

### Groups & structure
```javascript
const group = draw.group().addClass('scene');
group.add(rect); group.add(circle);
group.transform({ rotate: 45, origin: 'center' });
const use = draw.use(symbolId);                    // reuse a <symbol>
const nested = draw.nested().size(100, 100);
```

### Gradients & patterns
```javascript
const grad = draw.gradient('linear', add => {      // 'linear' | 'radial'
  add.stop(0, '#333');
  add.stop(1, '#fff');
}).from(0, 0).to(1, 1);
rect.fill(grad);

const pattern = draw.pattern(20, 20, add => {
  add.rect(20, 20).fill('#f06');
  add.rect(10, 10).fill('#0f9');
});
circle.fill(pattern);
```

### Filters (via @svgdotjs/svg.filter.js plugin)
```javascript
import '@svgdotjs/svg.filter.js';
rect.filterWith(add => {
  const blur = add.gaussianBlur(2);
  add.offset(3, 3).in(blur).colorMatrix('matrix', [/* drop shadow */]);
});
```

## Animation
```javascript
// Fluent runners
rect.animate(1000).move(100, 100);                 // duration ms
rect.animate({ duration: 800, delay: 200, ease: '<>' }).rotate(45).scale(1.5);
circle.animate(2000).fill('#f06').loop(true, true); // loop, reverse (swing)

// Timeline for coordinated sequences
rect.animate(500).move(50, 50)
    .after(() => rect.animate(500).fill('#0af'));

// Manual value tween
el.animate(1000).during(pos => el.center(pos * 300, 150));
```
Easing tokens: `'-'` (ease-in), `'<'` (ease-out), `'>'` (ease-in), `'<>'` (ease-in-out), or a custom function.

## Events & Interactivity
```javascript
rect.on('click', e => rect.fill('#f06'));
rect.on('mouseover', () => rect.animate(150).scale(1.1));
rect.on('mouseout',  () => rect.animate(150).scale(1));
rect.off('click');
rect.fire('customEvent');
```

## How-To (worked recipes)

### How to add colour, gradients, and stateful styling
```javascript
const draw = SVG().addTo('#chart').size(320, 200);
const g = draw.gradient('linear', add => { add.stop(0, '#ff6b6b'); add.stop(1, '#4ecdc4'); });
const bar = draw.rect(240, 40).move(40, 80).fill(g).radius(6);
bar.addClass('bar');                       // style :hover etc. in CSS
bar.on('mouseenter', () => bar.animate(150).fill('#ffd93d'));
bar.on('mouseleave', () => bar.animate(150).fill(g));
```
Prefer CSS classes for hover/selected states; use `fill()`/gradients for data-driven colour.

### How to build a reusable icon factory
```javascript
function star(draw, x, y, size = 40, color = '#ffd700') {
  const s = draw.polygon('50,0 61,35 98,35 68,57 79,91 50,70 21,91 32,57 2,35 39,35')
    .size(size, size).move(x, y).fill(color).stroke({ color: '#ffa500', width: 2 });
  return s;
}
star(draw, 20, 20); star(draw, 80, 20, 30, '#ff6b6b');
```

### How to animate an element along a path
```javascript
const path = draw.path('M 20 100 C 100 20, 220 180, 300 100').fill('none').stroke('#ccc');
const dot = draw.circle(12).fill('#f06');
const len = path.length();
dot.animate(3000).during(pos => {
  const p = path.pointAt(pos * len);
  dot.center(p.x, p.y);
}).loop();
```

### How to data-bind a small bar chart
```javascript
const data = [30, 80, 45, 60, 20];
const draw = SVG().addTo('#c').size(300, 120);
data.forEach((v, i) => {
  draw.rect(40, v).move(i * 55 + 10, 100 - v).fill('#4ecdc4')
      .animate(400).attr('height', v);
});
```

## Do's and Don'ts

### ✅ Do
- Use `move()` for top-left and `center()` for centred placement — mixing them up is the most common positioning bug.
- Prefer CSS classes (`addClass`) for interaction states so styling lives in your stylesheet.
- Group related elements (`draw.group()`) and transform/animate the group as a unit.
- Reuse geometry with `<symbol>` + `draw.use()` when you render many identical shapes.
- Set `transform({ ..., origin: 'center' })` so rotations/scales pivot correctly.

### ❌ Don't
- Don't render thousands of animated nodes — SVG DOM gets heavy; switch to `canvas-api` for high element counts / particle systems.
- Don't confuse `circle(d)` (diameter) with a radius argument — it takes the diameter.
- Don't forget filters need the separate `svg.filter.js` plugin; the core lib doesn't include them.
- Don't animate layout-affecting attributes in tight loops without `requestAnimationFrame` batching — SVG.js runners handle timing, hand-rolled loops may thrash.

## Advanced Features
- **Plugins**: `svg.filter.js` (filters), `svg.draggable.js` (drag), `svg.panzoom.js` (pan/zoom), `svg.topath.js` (shape→path).
- **Server-side**: pair with `svgdom` + `window`/`document` injection to generate SVG strings in Node (`draw.svg()` returns markup).
- **Export**: `draw.svg()` gives the SVG source; feed it to `svg2pdf.js`, or rasterize via `canvas`/`sharp`.
- **Matrix control**: `el.matrix()`, `el.transform()` for precise affine transforms.

## Common Pitfalls & Troubleshooting
- *Shape appears at 0,0* → you sized but never `move()`/`center()`ed it.
- *Filters do nothing* → `svg.filter.js` plugin not imported.
- *Rotation jumps* → no transform `origin`; defaults to element origin, not centre.
- *Nothing renders in Node* → missing `svgdom` window/document setup.
- *Performance tanks* → too many live nodes/animations; consolidate into paths or move to canvas.

## Best For / Avoid For
`interactive-svg`, `icons`, `diagrams`, `generative-art`, `small-charts`, `path-animation`, `hit-testable-graphics` — pick SVG.js for scalable, event-driven vector scenes with manageable element counts.
Avoid for: very high element counts / 60fps particle fields (use `canvas-api`), heavy data-join pipelines (use D3), or 3D (WebGL/three.js).

## See Also
- `canvas-api.md` — immediate-mode raster alternative for high-FPS/high-count scenes
- `svg2pdf.md` — export the SVG you build to a vector PDF
- `node-canvas.md` — rasterize generated SVG server-side
- `html.md` — the host page and CSS that style your classes
- `../use-case/vector-graphics.md`, `../use-case/data-visualization.md`
