# Mo.js

## What
A declarative motion-graphics library for the web, specializing in shape animation, custom SVG shapes, motion paths, and particle "burst" effects. Its consumer is the browser (SVG-based rendering); output is animated motion-graphic elements.

## How
- The LLM emits Mo.js JavaScript that declares animated objects: `new mojs.Shape({ shape: 'circle', scale: {0:1}, duration: 1000, easing: 'elastic.out' }).play()`, `new mojs.Burst({ radius: {0:100}, count: 5, children: {...} }).play()`, and `new mojs.Timeline()` to sequence them.
- Load via CDN (`@mojs/core`) or `import mojs from '@mojs/core'`. Property animations use the `{from: to}` object syntax (e.g. `strokeWidth: {10:0}`); custom shapes extend `mojs.CustomShape` and register via `mojs.addShape('heart', Heart)`; motion along a path is set with `path: document.querySelector('#path')`.
- Typical final artifact: expressive SVG motion-graphic effects — bursts/explosions, morphing shapes, trailing accents, playful UI micro-interactions.

## Why
- Reach for Mo.js when the goal is *motion graphics* flair — bursts, custom-shape animation, and declarative playful effects — rather than general-purpose element tweening.
- Limitations: it is specialized toward shape/burst motion graphics, so it is a narrower tool than a general animation platform; the declarative `{from:to}` model and custom-shape registration are a distinct API to learn.
- Relative to siblings: mo_js is the motion-graphics/effects specialist of this category. Choose it for burst and custom-shape spectacle; choose gsap for heavy timeline orchestration, anime_js for lightweight general tweening, or velocity_js for jQuery-style UI transitions.

## Source
- Solution reference: `fim/solution/mo_js.md`
