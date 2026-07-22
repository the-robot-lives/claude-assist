# Lottie — render After Effects animations on web & mobile

Lottie plays vector animations exported from Adobe After Effects (via the **Bodymovin** plugin) as compact JSON, rendering them natively as SVG/Canvas/HTML in the browser (and via native SDKs on iOS/Android/Flutter/React Native). Designers author complex motion in AE; developers drop in a `.json` (or `.lottie` dotLottie) file and get resolution-independent, tiny, controllable animation — no video, no sprite sheets. `lottie-web` is the canonical web player; `@dotlottie/player-component` / `@lottiefiles/dotlottie-web` are the modern web-component players.

**Current Version**: `lottie-web` 5.12.x (current major); dotLottie players 0.3x+ **License**: MIT (lottie-web) **Bundle/Runtime**: `lottie.min.js` ~250 KB (~60 KB gz); lighter `lottie_light` build available (SVG-only).

## Official Resources & Documentation
- **LottieFiles** (marketplace + tools): https://lottiefiles.com/
- **lottie-web repo**: https://github.com/airbnb/lottie-web
- **npm**: https://www.npmjs.com/package/lottie-web
- **dotLottie player**: https://github.com/LottieFiles/lottie-player
- **Bodymovin (AE exporter)**: https://github.com/airbnb/lottie-web/tree/master/build/player
- **LottieFiles editor / preview**: https://lottiefiles.com/tools/lottie-editor
- **Docs**: https://airbnb.io/lottie/

## Installation & Setup

### Package manager
```bash
npm install lottie-web
# modern web component alternative:
npm install @lottiefiles/dotlottie-web   # or @dotlottie/player-component
```

### CDN — lottie-web
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js"></script>
```

### CDN — dotLottie web component (simplest drop-in)
```html
<script src="https://unpkg.com/@dotlottie/player-component@latest/dist/dotlottie-player.mjs" type="module"></script>
<dotlottie-player src="animation.lottie" autoplay loop style="width:300px"></dotlottie-player>
```

### Import
```javascript
import lottie from 'lottie-web';
// or SVG-only, smaller: import lottie from 'lottie-web/build/player/lottie_light';
```

## Core Syntax / API Reference

### `loadAnimation` — the entry point
```javascript
const anim = lottie.loadAnimation({
  container: document.getElementById('lottie'),  // required DOM host
  renderer: 'svg',            // 'svg' | 'canvas' | 'html'
  loop: true,                 // boolean or a number of loops
  autoplay: true,
  path: 'data.json',          // URL to the exported JSON…
  // …OR inline the data:
  // animationData: jsonObject,
  rendererSettings: {
    preserveAspectRatio: 'xMidYMid meet',   // like CSS object-fit
    progressiveLoad: true,                  // canvas: render as it parses
    clearCanvas: true,
  },
});
```

### Playback control (AnimationItem)
```javascript
anim.play();
anim.pause();
anim.stop();               // pause + reset to frame 0
anim.setSpeed(2);          // 2× speed (negative not supported; use setDirection)
anim.setDirection(-1);     // 1 forward, -1 reverse
anim.goToAndStop(60, true);   // (value, isFrame) — true=frames, false=milliseconds
anim.goToAndPlay(0.5, false); // jump to 500ms and play
anim.playSegments([0, 120], true);          // play frames 0→120
anim.playSegments([[0,30],[60,90]], true);  // queue multiple segments
anim.setSubframe(false);   // disable subframe interpolation (crisper, cheaper)
anim.destroy();            // free the animation (call on unmount!)
```

### Properties & events
```javascript
anim.totalFrames;  anim.frameRate;  anim.currentFrame;  anim.playDirection;
anim.addEventListener('DOMLoaded',    () => {});   // structure built
anim.addEventListener('complete',     () => {});   // finished (non-looping)
anim.addEventListener('loopComplete',  () => {});
anim.addEventListener('enterFrame',   (e) => e.currentTime); // fires each frame
anim.addEventListener('segmentStart',  () => {});
anim.addEventListener('data_ready',    () => {});
anim.addEventListener('data_failed',   () => {});  // JSON load error
```

### Global config
```javascript
lottie.setQuality('high');   // 'high' | 'medium' | 'low' — subframe/AA tradeoff
lottie.setLocationHref(location.href);  // fixes SVG masks/gradients on <base>/routing
lottie.registerAnimation(el);           // scan [data-animation-path] elements
```

## Renderers / Output Types
- **`svg`** (default) — crisp, scalable, DOM-inspectable, supports masks/mattes/text; heavier DOM for complex art.
- **`canvas`** — better perf for busy animations / many instances; no DOM nodes; some AE features (certain masks) limited.
- **`html`** — HTML+CSS 3D transforms; niche.
- **dotLottie (`.lottie`)** — zipped bundle of one or more JSON animations + assets; smaller and multi-animation; played by the dotLottie players.

### Renderer selection guide
| Situation | Renderer |
|---|---|
| Single crisp hero icon, needs to scale/zoom | `svg` |
| Many simultaneous animations, or complex/busy art | `canvas` |
| Mobile performance-critical | `canvas` (+ `setSubframe(false)`) |
| Need to inspect/style individual shapes via DOM | `svg` |
| Smallest payload + multiple animations in one file | dotLottie `.lottie` |

## How-To

### How to recolor / theme a Lottie (mandatory styling recipe)
Colors are baked into the exported JSON per-shape, so "styling" means either (a) CSS on the SVG output, (b) editing the JSON color arrays, or (c) using the LottieFiles color API/editor. Colors in Lottie JSON are `[r, g, b, a]` floats in **0–1**.
```javascript
// (a) Quick CSS tint of the whole SVG (crude but instant):
container.querySelector('svg').style.filter = 'hue-rotate(120deg) saturate(1.2)';

// (b) Recolor a known layer/shape by rewriting the color keyframe (0–1 RGBA):
function recolor(data, hex) {
  const [r, g, b] = hex.match(/\w\w/g).map(h => parseInt(h, 16) / 255);
  // walk data.layers[].shapes[] and set fill color .c.k = [r,g,b,1] where it matches
  JSON.stringify(data, (k, v) => {
    if (k === 'c' && v && Array.isArray(v.k) && v.k.length === 4) v.k = [r, g, b, 1];
    return v;
  });
  return data;
}
const anim = lottie.loadAnimation({ container, renderer: 'svg',
  animationData: recolor(structuredClone(jsonData), '4f8cff'), autoplay: true, loop: true });
```
For maintainable theming, ask the designer to name layers and expose colors, or use the dotLottie player's theming / LottieFiles "colors" tooling. The robust route is editing the source JSON, not CSS filters.

### How to scrub a Lottie on scroll
```javascript
const anim = lottie.loadAnimation({ container, renderer: 'svg', loop: false, autoplay: false, path: 'scene.json' });
addEventListener('scroll', () => {
  const p = scrollY / (document.body.scrollHeight - innerHeight);
  anim.goToAndStop(p * anim.totalFrames, true);   // frame = scroll progress
});
```

### How to play interaction segments (hover in/out)
```javascript
const anim = lottie.loadAnimation({ container, animationData: data, autoplay: false, loop: false });
trigger.addEventListener('mouseenter', () => anim.playSegments([0, 30], true));
trigger.addEventListener('mouseleave', () => anim.playSegments([30, 0], true));
```
The dotLottie/`@lottiefiles/lottie-interactivity` library provides declarative scroll/hover/cursor "interactivity" modes.

### How to use the web component (no JS wiring)
```html
<dotlottie-player src="/loader.lottie" autoplay loop
                  speed="1" mode="bounce" style="width:200px;height:200px"></dotlottie-player>
```

### How to play named markers instead of hardcoded frames
After Effects markers export into the JSON; play by name for maintainable segments.
```javascript
const anim = lottie.loadAnimation({ container, path: 'flow.json', autoplay: false });
anim.addEventListener('DOMLoaded', () => {
  // markers live on anim.markers = [{ payload, time, duration, cm }]
  const intro = anim.markers.find(m => m.cm === 'intro');
  anim.playSegments([intro.time, intro.time + intro.duration], true);
});
```

### How to use Lottie in React
```jsx
import { useLottie } from 'lottie-react';
import data from './animation.json';
function Icon() {
  const { View, play, pause, setSpeed } = useLottie({ animationData: data, loop: true, autoplay: false });
  return <div onMouseEnter={play} onMouseLeave={pause}>{View}</div>;
}
// dotLottie: import { DotLottieReact } from '@lottiefiles/dotlottie-react';
```

## Do's and Don'ts

### ✅ Do
- Prefer **dotLottie (`.lottie`)** for production — smaller, supports multiple animations + theming.
- Call `anim.destroy()` on unmount (SPAs) to avoid leaks and duplicate RAF loops.
- Choose `canvas` renderer for many simultaneous/complex animations; `svg` for crisp scalable single hero pieces.
- Set `preserveAspectRatio` to control fit/crop.
- Ask designers to keep AE files simple (avoid unsupported effects) and name layers for later theming.

### ❌ Don't
- Don't expect to freely restyle arbitrary colors via CSS — colors are in the JSON; CSS `filter` is a blunt instrument.
- Don't use unsupported After Effects features (many effects, expressions, some blend modes, auto-trace) — Bodymovin silently drops them.
- Don't ship giant JSON with huge embedded raster images — that defeats Lottie's size advantage; keep art vector.
- Don't run dozens of `svg` renderers on mobile — DOM cost is high; switch to canvas or fewer instances.
- Don't forget markers: name AE markers to drive `playSegments` reliably instead of hardcoding frame numbers.

## Styling, Theming & Customization
- **Color/theming**: edit JSON color keyframes (0–1 RGBA), use dotLottie themes, or LottieFiles' color editor; CSS `filter` for quick global tints.
- **Fit**: `rendererSettings.preserveAspectRatio` ('xMidYMid meet' contain, 'xMidYMid slice' cover).
- **Speed/direction/quality**: `setSpeed`, `setDirection`, `lottie.setQuality`.
- **Markers**: named AE markers → segment playback anchors.
- **Expressions/slots** (newer): parameterized colors/values via dotLottie for runtime theming.

## Advanced Features
- **dotLottie** multi-animation bundles + state machines (interactive flows).
- **`lottie-interactivity`** — declarative scroll/cursor/hover sync.
- **Segment queuing** — chain multiple frame ranges.
- **Canvas offscreen / worker** rendering for heavy scenes (via community wrappers).
- **Native parity** — same JSON runs on iOS/Android/Flutter/React Native SDKs.

## Common Pitfalls & Troubleshooting
- **Animation looks wrong / parts missing** — AE used features Bodymovin doesn't support (effects, expressions, certain mattes). Re-export simplified.
- **Blank / `data_failed`** — bad path, CORS on the JSON, or malformed export.
- **Gradients/masks broken after routing** — call `lottie.setLocationHref(location.href)` (SVG `url(#id)` refs break under `<base>`/SPA routes).
- **Janky on mobile** — too many `svg` renderers; switch to `canvas`, reduce instances, disable subframe.
- **Colors won't change via CSS** — they're in the JSON; edit source or use theming APIs.
- **Memory grows in SPA** — animations not `destroy()`ed on unmount.

## Integration Notes
- **React**: `lottie-react` or `@lottiefiles/react-lottie-player` / `@dotlottie/react-player`; or wrap `lottie-web` in `useEffect` + cleanup.
- **Vue/Angular/Svelte**: official/community wrappers, or the framework-agnostic web component.
- **Next.js**: client-only (`ssr:false`); JSON served statically or imported.

## Best For / Avoid For
`ui-animations`, `loaders`, `onboarding-illustrations`, `icon-animations`, `marketing-hero-motion`, `cross-platform-animation` — choose Lottie when a designer authors motion in After Effects and you need it identical on web + native at tiny size.
Avoid for: programmatic/data-driven animation (GSAP, mo.js), 3D (three.js), or effects AE→Bodymovin can't export.

## See Also
- `gsap.md`, `mo_js.md`, `velocity_js.md` — code-driven animation
- `two_js.md`, `rough_js.md` — programmatic vector drawing
- `../use-case/creative-animation.md` — animation solution selection
