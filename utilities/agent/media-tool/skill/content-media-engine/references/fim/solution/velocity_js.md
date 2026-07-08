# Velocity.js — fast DOM/SVG property animation

Velocity.js is a lightweight animation engine with a jQuery-`.animate()`-style API that runs independently of jQuery. It animates CSS transforms, colors, and SVG attributes with hardware-accelerated performance, supports chained/queued sequences, scroll-to animation, and a set of prebuilt UI "transition" effects. It filled the niche between jQuery animation and GSAP; today it's a solid, small choice for straightforward UI motion where you don't need GSAP's timeline/plugin depth.

**Current Version**: `velocity-animate` 2.0.6 (current major; maintenance mode) **License**: MIT **Bundle/Runtime**: ~30 KB gz; animates DOM/SVG via requestAnimationFrame.

## Official Resources & Documentation
- **Docs**: http://velocityjs.org/
- **Repo**: https://github.com/julianshapiro/velocity
- **npm**: https://www.npmjs.com/package/velocity-animate
- **UI Pack (transitions)**: http://velocityjs.org/#uiPack

## Installation & Setup

### Package manager
```bash
npm install velocity-animate
```
```javascript
import Velocity from 'velocity-animate';
```

### CDN
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/velocity/2.0.6/velocity.min.js"></script>
<!-- optional prebuilt transition effects: -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/velocity/2.0.6/velocity.ui.min.js"></script>
```
With jQuery present, `$('.el').velocity({...})` also works; without it, use the standalone `Velocity(element, ...)` form.

## Core Syntax / API Reference

### Call signature
```javascript
Velocity(element, propertiesMap, optionsMap);
Velocity(element, propertiesMap, duration, easing, complete);  // shorthand args
Velocity(element, 'effectName', options);                       // prebuilt effect / command
```
`element` = a DOM element, NodeList, or array of elements.

### Animate properties
```javascript
Velocity(document.querySelector('.box'), {
  translateX: '200px',      // transforms are first-class: translateX/Y/Z, rotateZ, scale, skewX
  rotateZ: '45deg',
  opacity: 0.5,
  width: '300px',
}, {
  duration: 1000,           // ms
  easing: 'easeInOutQuad',
  delay: 100,
  loop: 2,                  // number, or true for infinite
  begin: (els) => {},
  progress: (els, complete, remaining) => {},
  complete: (els) => {},
});
```
Velocity accumulates transforms independently, so `translateX` and `rotateZ` compose without you writing a `transform` string.

### Easing
```javascript
easing: 'linear' | 'swing' | 'ease' | 'easeIn' | 'easeOut' | 'easeInOut'
easing: 'easeInOutQuad' | 'easeOutCubic' | 'easeInQuart' | 'easeOutExpo' | 'easeInOutBack' // full jQuery-UI set
easing: [0.17, 0.67, 0.83, 0.67]     // cubic bezier control points
easing: [250, 15]                     // spring physics: [tension, friction]
easing: 'spring'
```

### Chaining & queuing
```javascript
Velocity(el, { opacity: 1, scale: 1.2 }, 500)
  .then(() => Velocity(el, { scale: 1 }, 300))
  .then(() => Velocity(el, 'reverse', 200));   // 'reverse' replays previous animation backward
// Same-element calls queue automatically; parallel with { queue: false }.
Velocity(el, { translateY: '10px' }, { queue: false, duration: 200 });
```

### Commands
```javascript
Velocity(el, 'stop');           // stop current animation
Velocity(el, 'finish');         // jump to end
Velocity(el, 'pause');  Velocity(el, 'resume');
Velocity(el, 'reverse');
Velocity(el, 'fadeIn',  { duration: 800 });   // built-in fade/slide
Velocity(el, 'fadeOut', { duration: 400 });
Velocity(el, 'slideUp'); Velocity(el, 'slideDown');
```

### Scroll animation
```javascript
Velocity(targetEl, 'scroll', { duration: 800, offset: -50, easing: 'easeOutQuart',
                               container: document.querySelector('.scroll-box') });
```

## Effects / Output Types
- **Transforms & opacity** (hardware-accelerated).
- **Colors** — `backgroundColor`, `color`, `borderColor` (hex/rgb).
- **SVG attributes** — `strokeDashoffset`, `fill`, `strokeWidth`, `x/y/cx/cy`, `d` (path via plugins).
- **Layout** — `width/height/top/left/margins` (reflow-triggering; use sparingly).
- **Scroll** — animated scroll-to.
- **UI Pack transitions** — `transition.fadeIn/Out`, `transition.slideUpIn`, `transition.flipXIn`, `callout.bounce/shake/flash`, etc. (requires `velocity.ui`).

## How-To

### How to animate colors & appearance (mandatory styling recipe)
Velocity tweens color properties directly (hex/rgb), alongside transforms and opacity. Combine into one call for coordinated motion + color change.
```javascript
Velocity(document.querySelector('.card'), {
  backgroundColor: '#4f8cff',
  color: '#ffffff',
  borderColor: '#2456b0',
  boxShadowBlur: '20px',     // some shadow sub-props supported via plugins
  translateY: ['0px', '40px'],   // [end, start] forcefeed: animate FROM 40px TO 0px
  opacity: [1, 0],
}, { duration: 700, easing: 'easeOutCubic' });
```
The `[end, start]` "forcefeed" array sets an explicit start value (like `fromTo`). Colors interpolate in RGB; use HSL-ish transitions by staging multiple steps.

### How to build entrance/exit sequences (UI Pack)
```javascript
// requires velocity.ui.js
Velocity(el, 'transition.slideUpIn',  { duration: 600, stagger: 100 });   // enter
Velocity(el, 'transition.slideDownOut', { duration: 400 });               // leave
Velocity(nodeList, 'transition.fadeIn', { stagger: 80, drag: true });     // staggered list reveal
```

### How to stagger a list
```javascript
const items = document.querySelectorAll('.item');
Velocity(items, { opacity: [1, 0], translateY: [0, 20] },
         { duration: 500, stagger: 100 });   // each item 100ms after the previous
```

### How to animate an SVG stroke draw-on
```javascript
Velocity(path, { strokeDashoffset: [0, pathLength] }, { duration: 2000, easing: 'easeInOutSine' });
// set path.style.strokeDasharray = pathLength first
```

### How to loop attention effects
```javascript
Velocity(el, { scale: 1.1 }, { duration: 300, loop: true });   // pulsing (yoyo via loop)
```

### How to reveal elements as they scroll into view
```javascript
const io = new IntersectionObserver((entries) => {
  entries.forEach((e) => {
    if (e.isIntersecting) {
      Velocity(e.target, { opacity: [1, 0], translateY: [0, 30] }, { duration: 600, easing: 'easeOutCubic' });
      io.unobserve(e.target);
    }
  });
}, { threshold: 0.2 });
document.querySelectorAll('.reveal').forEach((el) => io.observe(el));
```

### Options reference (full map)
```javascript
Velocity(el, properties, {
  duration: 1000,      // ms, or 'slow'|'normal'|'fast'
  easing: 'easeInOutQuad',   // named | [x1,y1,x2,y2] bezier | [tension, friction] spring
  delay: 0,            // ms before start
  loop: 2,             // number of yoyo cycles, or true (infinite)
  repeat: 1,           // repeats WITHOUT reversing
  queue: 'fx',         // false = run in parallel; custom queue name to sequence
  begin: (els) => {},
  progress: (els, complete, remaining, start, tweenValue) => {},
  complete: (els) => {},
  visibility: 'hidden',   // set display/visibility at end (e.g. hidden after fadeOut)
  display: 'none',
  mobileHA: true,      // mobile hardware acceleration
});
```

## Do's and Don'ts

### ✅ Do
- Animate transforms (`translateX`, `scale`, `rotateZ`) and `opacity` for smooth, GPU-friendly motion.
- Use the `[end, start]` forcefeed array when you need an explicit starting value.
- Use `{ queue: false }` for animations that should run in parallel on the same element.
- Load `velocity.ui.js` to get the transition/callout effect library.
- Use `.then()`/`complete` for sequencing rather than nested timeouts.

### ❌ Don't
- Don't animate `width/height/top/left/margin` when transforms suffice — layout props force reflow and jank.
- Don't expect GSAP-level timelines/plugins — Velocity is deliberately smaller; sequence via chaining.
- Don't forget durations are milliseconds.
- Don't rely on `transition.*`/`callout.*` names without including the UI Pack script.
- Don't mix CSS transitions with Velocity on the same property — they fight.

## Styling, Theming & Customization
- **Colors**: `backgroundColor`, `color`, `borderColor`, plus per-channel (`backgroundColorRed`, etc.).
- **Easing**: named jQuery-UI eases, cubic-bezier arrays, or spring `[tension, friction]`.
- **Transforms**: independent `translateX/Y/Z`, `rotateX/Y/Z`, `scaleX/Y`, `skewX/Y` that compose.
- **UI Pack**: prebuilt transitions/callouts as your "effect theme."

## Advanced Features
- **Spring physics easing** via `[tension, friction]`.
- **Promise interface** (`.then`) for async sequencing.
- **`stagger` + `drag`** for cascading list animations.
- **Scroll** command with container/offset.
- **`mock`** flag to fast-forward animations in tests.

## Common Pitfalls & Troubleshooting
- **`transition.*` does nothing** — UI Pack (`velocity.ui.js`) not loaded.
- **Janky layout animation** — animating reflow properties; switch to transforms.
- **No animation / instant jump** — element not in DOM, `display:none`, or duration `0`.
- **Colors won't animate** — property not a supported color prop, or value not hex/rgb.
- **Conflicts / snapping** — a CSS transition on the same property, or overlapping queued animations (use `stop` first).
- **jQuery vs standalone confusion** — standalone uses `Velocity(el, ...)`; the `$.fn` form needs jQuery.

## Integration Notes
- Works with or without jQuery; standalone form is preferred in modern apps.
- In React/Vue, call in lifecycle hooks and `Velocity(el, 'stop')` on unmount.
- Maintenance-mode project: for new complex work, GSAP is the more actively developed choice; Velocity remains fine for simple UI motion at small size.

## Best For / Avoid For
`ui-transitions`, `list-reveals`, `scroll-to`, `simple-micro-interactions`, `jquery-migration` — choose Velocity for lightweight, straightforward DOM/SVG animation with a familiar API.
Avoid for: complex timeline choreography / scroll storytelling (GSAP), After Effects playback (Lottie), or 2D/3D scene rendering (Two.js/three.js).

## See Also
- `gsap.md` — heavier, timeline/plugin-rich animation engine
- `mo_js.md` — burst/motion-graphics animation
- `lottie.md` — designer-authored animation playback
- `../use-case/creative-animation.md` — animation solution selection
