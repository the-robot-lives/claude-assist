# mo.js — motion graphics for the web

mo.js is a declarative motion-graphics toolkit focused on **bursts, shape animation, and choreographed timelines** rendered as SVG. Instead of tweening arbitrary DOM properties (GSAP's domain), mo.js gives you purpose-built modules — animated `Shape`s, particle `Burst`s, `Html` element animation, and a `Timeline` — with a distinctive "delta" syntax (`{ from: to }`) for animatable properties. It excels at playful UI feedback: tap ripples, like-button explosions, loaders, and micro-interactions.

**Current Version**: `@mojs/core` 0.288.x+ (current major) **License**: MIT **Bundle/Runtime**: ~60 KB gz core; renders SVG into the DOM. Companion tools: `@mojs/player`, `@mojs/curve-editor`, mojs-timeline-editor.

## Official Resources & Documentation
- **Site / tutorials**: https://mojs.github.io/
- **API docs**: https://mojs.github.io/api/
- **Repo**: https://github.com/mojs/mojs
- **npm**: https://www.npmjs.com/package/@mojs/core
- **Playground**: https://codepen.io/collection/nVJqLd (official demos)
- **Curve editor**: https://mojs.github.io/tools/

## Installation & Setup

### Package manager
```bash
npm install @mojs/core
```
```javascript
import mojs from '@mojs/core';
```

### CDN
```html
<script src="https://cdn.jsdelivr.net/npm/@mojs/core"></script>
```

## Core Syntax / API Reference

### The delta `{ from: to }` syntax
mo.js's defining idiom: any animatable property can be a `{ start: end }` object, optionally with a unit or easing.
```javascript
scale:  { 0: 1 }                 // animate scale 0 → 1
radius: { 50: 0 }                // 50 → 0
x:      { 0: 200 }               // px
angle:  { 0: 360 }
fill:   { 'cyan': 'magenta' }    // color delta
strokeWidth: { 10: 0, easing: 'cubic.out' }  // per-property easing via object form
```

### `mojs.Shape` — animated SVG shape
```javascript
const circle = new mojs.Shape({
  parent: document.body,       // where to inject the SVG (default: body)
  shape: 'circle',             // circle, rect, polygon, line, cross, equal, curve, zigzag
  left: '50%', top: '50%',     // position
  radius: { 0: 50 },
  fill: { 'orange': 'red' },
  stroke: '#333', strokeWidth: { 4: 0 },
  scale: { 0: 1 },
  duration: 1000, delay: 0,
  easing: 'elastic.out',
  repeat: 2, isYoyo: true,
  onComplete: () => {},
}).play();
```

### `mojs.Burst` — particle explosion
```javascript
const burst = new mojs.Burst({
  left: 0, top: 0,
  radius: { 0: 100 },          // burst spreads to radius 100
  count: 8,                    // number of particles
  angle: 45,
  children: {                  // per-particle Shape config
    shape: 'circle',
    fill: { '#FD7', '#F64' },  // (delta) or array for per-particle variety
    radius: 10,
    scale: { 1: 0 },
    duration: 1500,
    easing: 'cubic.out',
  },
});
burst.tune({ x: 200, y: 150 }).replay();   // reposition + replay at a point
```

### `mojs.Html` — animate real HTML elements
```javascript
const el = new mojs.Html({
  el: '.badge',
  x: { 0: 120 },
  scale: { 1: 1.4 },
  rotateZ: { 0: 25 },
  duration: 800, easing: 'bounce.out',
}).play();
```

### `mojs.Timeline` — choreograph multiple modules
```javascript
const tl = new mojs.Timeline({ repeat: 3, speed: 1 });
const ring  = new mojs.Shape({ shape: 'circle', fill: 'none', stroke: '#0f0',
                               strokeWidth: { 20: 0 }, radius: { 0: 60 }, duration: 600 });
const burst = new mojs.Burst({ radius: { 0: 90 }, count: 6, duration: 900 });
tl.add(ring, burst);           // add modules
tl.play();
// offset control: tl.add(burst, ring) then per-module `delay`, or nested timelines
```

### `mojs.CustomShape` — register your own SVG path
```javascript
class Heart extends mojs.CustomShape {
  getShape() { return '<path d="M92.5,7.5c-16.6,0-30,13.4-30,30c0,30,30,60,30,60s30-30,30-60C122.5,20.9,109.1,7.5,92.5,7.5z"/>'; }
}
mojs.addShape('heart', Heart);
new mojs.Shape({ shape: 'heart', fill: '#ff0066', scale: { 0: 2 }, duration: 1000 }).play();
```

## Modules / Output Types
- **`Shape`** — single animated SVG primitive (circle, rect, polygon, cross, line, curve, zigzag, equal).
- **`Burst`** — radial particle systems from a `children` template.
- **`Html`** — animate existing DOM elements (transforms only, not layout).
- **`ShapeSwirl`** — burst particle variant with curved, swirling motion.
- **`Timeline`** — sequence/parallelize modules.
- **`Tween`** — low-level generic tween (drive anything via `onUpdate`).
- Output is always injected **SVG** (plus transforms on your HTML for `Html`).

## How-To

### How to add colors & style the motion (mandatory styling recipe)
Color and stroke are animatable via the delta syntax; fill/stroke accept hex, names, rgba, and `{from: to}` deltas. Per-particle color variety comes from arrays.
```javascript
const pulse = new mojs.Shape({
  shape: 'circle',
  fill: { '#4f8cff': '#ff4f8c' },      // animate fill color
  stroke: { '#ffffff': 'rgba(255,255,255,0)' },
  strokeWidth: { 12: 0 },
  radius: { 20: 90 },
  scale: { 0.4: 1 },
  opacity: { 1: 0 },
  duration: 1200,
  easing: 'sin.out',
}).play();

const confetti = new mojs.Burst({
  radius: { 0: 120 }, count: 12,
  children: {
    shape: ['circle', 'rect', 'polygon'],           // vary shape per particle
    fill: ['#FD7', '#F64', '#4f8cff', '#22c55e'],   // vary color per particle
    degreeShift: 'rand(-90, 90)',                   // random angular offset
    radius: 'rand(6, 14)',
    scale: { 1: 0 }, duration: 'rand(800, 1600)',
  },
}).play();
```
Use `'rand(min, max)'` string tokens for randomized per-particle values, and per-property easing via the object form (`{ 10: 0, easing: 'cubic.out' }`).

### How to fire a burst at a click position
```javascript
const burst = new mojs.Burst({ radius: { 0: 80 }, count: 10,
  children: { fill: ['#f00','#0f0','#00f'], scale: { 1: 0 }, duration: 900 } });
document.addEventListener('click', (e) => burst.tune({ x: e.pageX, y: e.pageY }).replay());
```

### How to sequence a "like" animation
```javascript
const scaleCurve = mojs.easing.path('M0,100 L25,99.9 C68,30 75,0 100,0');
const timeline = new mojs.Timeline();
const heart = new mojs.Html({ el: '.heart-icon', scale: { 0: 1 }, easing: scaleCurve, duration: 900 });
const ring  = new mojs.Shape({ shape: 'circle', fill: 'none', stroke: '#f5274e',
                               strokeWidth: { 15: 0 }, scale: { 0: 1 }, radius: 40, duration: 700 });
timeline.add(heart, ring).play();
```

### How to control playback
```javascript
const s = new mojs.Shape({ /* ... */ });
s.play(); s.replay(); s.pause();
s.play(); s.playBackward();
s.setProgress(0.5);          // scrub 0..1
s.setSpeed(2);
```

## Easing reference
```javascript
// Named easings (string form):
'linear.none'
'ease.in' | 'ease.out' | 'ease.inout'
'sin.in' | 'sin.out' | 'sin.inout'
'quad|cubic|quart|quint.in|out|inout'
'expo.in|out|inout'  'circ.in|out|inout'
'back.in|out|inout'  'elastic.in|out|inout'  'bounce.in|out|inout'
// Custom path easing (from the Curve Editor tool):
const ease = mojs.easing.path('M0,100 C21,100 40,50 100,0');
new mojs.Shape({ scale: { 0: 1, easing: ease }, duration: 800 });
// Bezier:
const b = mojs.easing.bezier(0.25, 0.1, 0.25, 1);
```

## Do's and Don'ts

### ✅ Do
- Use the `{ from: to }` delta syntax for every animatable property.
- Use `Burst`/`ShapeSwirl` for particle effects instead of hand-rolling many shapes.
- Randomize particles with `'rand(a, b)'` tokens and color/shape arrays.
- Reposition-and-replay bursts with `.tune({ x, y }).replay()` for click effects.
- Use `mojs.easing.path()` / the curve editor for bespoke, characterful easing.

### ❌ Don't
- Don't try to animate arbitrary DOM/layout properties with `Html` — it handles transforms/opacity, not `width`/`margin` (use GSAP for that).
- Don't forget `.play()` — modules don't animate until played.
- Don't leave many injected SVG shapes in the DOM after one-shot effects; reuse a module via `replay()` instead of `new` per click.
- Don't expect a huge plugin ecosystem — mo.js is focused on shapes/bursts/timelines.
- Don't set durations in seconds — mo.js uses **milliseconds**.

## Styling, Theming & Customization
- **Colors**: `fill`, `stroke` accept hex/name/rgba and deltas; arrays give per-particle variety in bursts.
- **Easing**: named (`elastic.out`, `bounce.out`, `cubic.inOut`, `sin.out`), custom via `mojs.easing.path()` or bezier, and the visual Curve Editor tool.
- **Shape set**: built-in primitives + `CustomShape` for any SVG path.
- **Origin/anchor**: `origin`, `x`/`y`/`angle` transforms; `radiusX`/`radiusY` for ellipses.

## Advanced Features
- **`ShapeSwirl`** — bursts with sinusoidal swirl paths for organic confetti/sparkle.
- **`Tween`** — generic engine: `new mojs.Tween({ duration, onUpdate(progress){...} })` to drive canvas/JS.
- **Nested timelines** for modular choreography.
- **Player & timeline editor** GUIs (`@mojs/player`, mojs-timeline-editor) for scrubbing/authoring.
- **`rand()` / stagger** expressions for procedural variety.

## Common Pitfalls & Troubleshooting
- **Nothing appears** — `.play()`/`.replay()` not called, or `parent`/`el` selector wrong.
- **Effect only fires once** — create the module once and call `.replay()`/`.tune().replay()`, don't rely on re-running `.play()` without reset.
- **Wrong position** — `left/top` vs `x/y`: `left/top` place the SVG; `x/y` are animated transforms relative to it.
- **Colors don't animate** — pass a delta `{ from: to }`, not a single value.
- **Timing feels off** — durations are ms, not seconds.
- **SVG piles up in DOM** — one-shot bursts injecting fresh SVG each click; reuse the instance.

## Integration Notes
- Framework-agnostic; in React create modules in `useEffect` and clean up (`module.el?.remove()` for injected nodes) on unmount.
- Pairs well with GSAP/ScrollTrigger (GSAP for layout/scroll, mo.js for burst accents).

## Best For / Avoid For
`micro-interactions`, `button-bursts`, `tap-ripples`, `loaders`, `playful-ui-feedback`, `svg-motion-graphics` — choose mo.js for characterful particle/shape moments.
Avoid for: complex scroll storytelling or arbitrary DOM-property animation (GSAP), After Effects playback (Lottie), or full 2D scene management (Two.js/Pixi).

## See Also
- `gsap.md` — general-purpose animation / scroll / layout
- `lottie.md` — designer-authored After Effects animations
- `velocity_js.md`, `two_js.md` — other animation/drawing libraries
- `../use-case/creative-animation.md` — animation solution selection
