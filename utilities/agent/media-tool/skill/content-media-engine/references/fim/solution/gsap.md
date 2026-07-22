# GSAP — GreenSock Animation Platform

GSAP is the industry-standard JavaScript animation engine: a high-performance tween/timeline system that animates any numeric property of DOM elements, SVG, canvas objects, WebGL/three.js objects, or plain JS objects. It's framework-agnostic, sequencing-first (timelines), and famous for buttery 60fps motion with a huge easing/plugin ecosystem (ScrollTrigger, SplitText, MorphSVG, Flip, Draggable). As of the Webflow acquisition, **the entire GSAP toolset including all previously "Club" plugins is free**.

**Current Version**: 3.13+ (npm `gsap`, current major 3.x) **License**: Standard "no charge" GSAP license (free, incl. all plugins). **Bundle/Runtime**: core ~50 KB min (~23 KB gz); plugins add modularly.

## Official Resources & Documentation
- **Docs**: https://gsap.com/docs/v3/
- **Ease visualizer**: https://gsap.com/docs/v3/Eases
- **ScrollTrigger docs**: https://gsap.com/docs/v3/Plugins/ScrollTrigger/
- **Repo**: https://github.com/greensock/GSAP
- **npm**: https://www.npmjs.com/package/gsap
- **Cheatsheet**: https://gsap.com/cheatsheet/
- **Forums**: https://gsap.com/community/

## Installation & Setup

### Package manager
```bash
npm install gsap
```

### CDN
```html
<script src="https://cdn.jsdelivr.net/npm/gsap@3/dist/gsap.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3/dist/ScrollTrigger.min.js"></script>
```

### Import + register plugins
```javascript
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { SplitText } from 'gsap/SplitText';
gsap.registerPlugin(ScrollTrigger, SplitText);   // register EVERY plugin before use
```

## Core Syntax / API Reference

### Tween methods
```javascript
gsap.to(target, vars);      // animate TO these values (most common)
gsap.from(target, vars);    // animate FROM these values to current
gsap.fromTo(target, fromVars, toVars);  // explicit start + end
gsap.set(target, vars);     // instantly set (no animation)
```
`target` = a CSS selector string, element, NodeList/array, or plain object. `vars` = properties + special config keys.
```javascript
gsap.to('.box', {
  x: 200,               // transforms: x/y/z, rotation, rotationX/Y, scale, scaleX/Y, skewX
  rotation: 360,        // degrees
  backgroundColor: '#f00',
  duration: 2,          // seconds
  delay: 0.5,
  ease: 'power2.inOut',
  repeat: 2,            // -1 = infinite
  yoyo: true,           // reverse on alternate repeats
  stagger: 0.1,         // when target is many elements
  onComplete: () => {}, onStart, onUpdate, onRepeat,
});
```
GSAP animates **transforms** (`x`, `y`, `scale`, `rotation`) via `transform`, not `left/top` — much faster and GPU-friendly.

### Timelines (sequencing)
A `Timeline` chains tweens with precise relative/absolute positioning.
```javascript
const tl = gsap.timeline({ repeat: -1, yoyo: true, defaults: { duration: 1, ease: 'power1.inOut' } });
tl.to('.a', { x: 100 })
  .to('.b', { y: 100 }, '-=0.5')   // start 0.5s BEFORE previous ends (overlap)
  .to('.c', { rotation: 180 }, '<') // start at SAME time as previous tween
  .to('.d', { scale: 2 }, '+=0.25') // 0.25s gap AFTER previous
  .to('.e', { opacity: 0 }, 2);     // absolute time: 2s from timeline start
```
Position parameter cheatsheet: `"+=n"` gap after, `"-=n"` overlap, `"<"` align to previous start, `">"` align to previous end, `"<0.2"` relative to previous start, `label` name.

### Easing
```javascript
ease: 'none'                                    // linear
ease: 'power1|power2|power3|power4.in|out|inOut'
ease: 'back.out(1.7)'  'elastic.out(1, 0.3)'  'bounce.out'  'expo.inOut'  'sine.inOut'
ease: 'steps(5)'                                // stepped
ease: CustomEase.create('name', 'M0,0 C0.2,0 0.1,1 1,1')  // plugin
```

### Stagger (animate many, offset in time)
```javascript
gsap.to('.grid-item', {
  scale: 1.4, duration: 0.5,
  stagger: { each: 0.05, grid: [5, 5], from: 'center', axis: null, ease: 'power2.in' },
});
// shorthand: stagger: 0.1  (each element 0.1s later)
```

### Control methods
```javascript
const anim = gsap.to('.x', { x: 300, duration: 2, paused: true });
anim.play(); anim.pause(); anim.reverse(); anim.restart();
anim.progress(0.5);      // scrub to 50%
anim.timeScale(2);       // 2× speed
anim.seek(1.0); anim.kill();
```

## Plugins / Output Types
- **ScrollTrigger** — scroll-driven animation, pinning, scrubbing, snapping (the flagship plugin).
- **SplitText** — split text into chars/words/lines for reveal animations.
- **Flip** — animate between layout states (FLIP technique) automatically.
- **Draggable / InertiaPlugin** — drag, throw, momentum.
- **MorphSVG / DrawSVG / MotionPath** — SVG shape morphing, line drawing, path following.
- **Observer** — unified pointer/wheel/touch input for gesture-driven animation.
- **Framework wrappers**: `@gsap/react` (`useGSAP` hook).

## How-To

### How to animate colors, transforms & style (mandatory styling recipe)
GSAP tweens CSS properties directly — including colors (hex/rgb/hsl), gradients (via CSS vars), and transforms. Use it as your "styling over time" engine.
```javascript
gsap.fromTo('.card',
  { backgroundColor: '#1a1a2e', color: '#888', boxShadow: '0 0 0 rgba(0,0,0,0)', y: 40, opacity: 0 },
  { backgroundColor: '#4f8cff', color: '#ffffff', boxShadow: '0 20px 40px rgba(79,140,255,0.4)',
    y: 0, opacity: 1, duration: 0.8, ease: 'power3.out', stagger: 0.12 }
);
// Animate a CSS custom property (great for gradients/themes):
gsap.to(':root', { '--brand-hue': 280, duration: 2 });
```
GSAP auto-detects color format and interpolates in RGB. For SVG fills/strokes just target `fill`, `stroke`, `stroke-dashoffset`.

### How to build a scroll-scrubbed animation (ScrollTrigger)
```javascript
gsap.registerPlugin(ScrollTrigger);
gsap.to('.parallax', {
  y: -200,
  ease: 'none',
  scrollTrigger: {
    trigger: '.parallax',
    start: 'top bottom',     // when top of trigger hits bottom of viewport
    end: 'bottom top',
    scrub: true,             // tie progress to scrollbar (true or a smoothing number)
    pin: false, markers: false,
  },
});
```

### How to reveal text on scroll (SplitText)
```javascript
gsap.registerPlugin(SplitText, ScrollTrigger);
const split = new SplitText('.headline', { type: 'chars, words' });
gsap.from(split.chars, {
  yPercent: 120, opacity: 0, duration: 0.6, ease: 'back.out(1.5)', stagger: 0.02,
  scrollTrigger: { trigger: '.headline', start: 'top 80%' },
});
```

### How to animate a plain object (drive canvas / three.js)
```javascript
const state = { value: 0 };
gsap.to(state, { value: 100, duration: 2, ease: 'power2.out',
  onUpdate: () => drawBar(state.value) });   // GSAP is your interpolation engine
// three.js: gsap.to(mesh.position, { x: 5, duration: 1 }); gsap.to(mesh.rotation, { y: Math.PI });
```

### How to use GSAP in React
```javascript
import { useGSAP } from '@gsap/react';
function Box() {
  const scope = useRef();
  useGSAP(() => { gsap.from('.item', { y: 30, opacity: 0, stagger: 0.1 }); },
          { scope });   // auto-cleanup on unmount
  return <div ref={scope}><div className="item"/></div>;
}
```

## Do's and Don'ts

### ✅ Do
- `gsap.registerPlugin()` for every plugin before using it.
- Animate transforms (`x`, `y`, `scale`, `rotation`) and `opacity` — they're GPU-accelerated.
- Use timelines for sequences instead of nested `setTimeout`/`delay` chains.
- Use `gsap.set()` for initial states to avoid flash-of-unstyled-content.
- In React, use `useGSAP` (or `gsap.context`) so animations clean up on unmount.
- Use `stagger` objects (`grid`, `from`) for grid/list reveals.

### ❌ Don't
- Don't animate `left`/`top`/`margin`/`width` when `x`/`y`/`scale` will do — layout properties trigger reflow and stutter.
- Don't create tweens inside a render/`draw` loop — build once, control with `play/reverse/progress`.
- Don't forget to `kill()` or scope animations in SPAs — orphaned tweens leak and fight each other.
- Don't rely on CSS transitions and GSAP on the same property simultaneously — they conflict.
- Don't set `duration` in milliseconds — GSAP uses **seconds**.

## Styling, Theming & Customization
- **Color/gradient theming**: tween CSS custom properties (`--hue`, `--brand`) and let CSS cascade.
- **Easing**: the visual signature of your motion — pick from power/back/elastic/bounce or `CustomEase`.
- **Defaults**: `gsap.timeline({ defaults: { ease, duration } })` and `gsap.defaults({...})` set global style.
- **Global config**: `gsap.config({ nullTargetWarn: false })`; `gsap.registerEffect()` to define reusable named animations.

## Advanced Features
- **`gsap.matchMedia()`** — responsive animations that (re)build per breakpoint and auto-revert.
- **`gsap.utils`** — `interpolate`, `mapRange`, `snap`, `wrap`, `random`, `clamp`, `pipe` for animation math.
- **MotionPath** — animate along an SVG path or coordinate array.
- **Flip** — animate arbitrary layout/DOM state changes (reorder, expand) smoothly.
- **quickSetter / quickTo** — hyper-optimized per-frame setters for mouse-follow effects.
- **Nested timelines** — add a timeline into another for modular choreography.

## Plugin quick-reference
| Plugin | Registers | Use for |
|---|---|---|
| ScrollTrigger | `ScrollTrigger` | scroll-scrubbed anim, pinning, snapping |
| SplitText | `SplitText` | per-char/word/line text reveals |
| Flip | `Flip` | animate layout/DOM state changes |
| Draggable | `Draggable` | drag/throw (with InertiaPlugin) |
| MotionPathPlugin | `MotionPathPlugin` | animate along an SVG path |
| MorphSVGPlugin | `MorphSVGPlugin` | morph one SVG path into another |
| DrawSVGPlugin | `DrawSVGPlugin` | line-draw / stroke reveal |
| Observer | `Observer` | unified wheel/touch/pointer gestures |
| ScrollSmoother | `ScrollSmoother` | smooth-scroll + parallax (needs ScrollTrigger) |

All are free under the current GSAP license. `gsap.registerPlugin(...)` each before use.

## Common Pitfalls & Troubleshooting
- **"Plugin not found" / no effect** — forgot `registerPlugin`.
- **Animation runs once, ignored on re-render (React)** — not scoped; use `useGSAP`/`gsap.context`.
- **Jank on scroll** — animating layout properties; switch to transforms; add `will-change` sparingly.
- **`from` leaves elements invisible** — an interrupted/overwritten `from` tween can strand the start state; prefer `fromTo` for critical reveals, or set `immediateRender: false`.
- **ScrollTrigger positions wrong after images load** — call `ScrollTrigger.refresh()` after content/layout changes.
- **Values snap instead of animate** — a conflicting CSS transition on the same property.

## Integration Notes
- **three.js / canvas / pixi**: animate object properties or a proxy object with `onUpdate` — GSAP is renderer-agnostic.
- **React**: `@gsap/react` `useGSAP`. **Vue/Svelte**: use `onMounted`/`onDestroy` with `gsap.context`.
- **Next.js**: register plugins client-side only.

## Best For / Avoid For
`ui-animation`, `scroll-storytelling`, `svg-animation`, `hero-sections`, `micro-interactions`, `timeline-choreography` — choose GSAP for precise, sequenced, high-performance web animation.
Avoid for: simple one-off CSS hover states (plain CSS transitions are lighter), full After Effects playback (use Lottie), or physics-heavy simulation (use a physics engine).

## See Also
- `lottie.md` — play designer-authored After Effects animations
- `velocity_js.md`, `mo_js.md`, `two_js.md` — other JS animation engines
- `../use-case/creative-animation.md` — animation solution selection
