# Lottie

## What
A framework for rendering After Effects animations natively on web and mobile from JSON animation data (exported via the Bodymovin plugin). Its consumer is the `lottie-web` player (with native mobile equivalents); output is vector animation played from a `.json` data file.

## How
- The LLM emits the *player integration* plus, conceptually, the JSON animation data: `lottie.loadAnimation({ container, renderer: 'svg', loop: true, autoplay: true, path: 'data.json' })` — the `data.json` is exported from After Effects, or passed inline as `animationData`.
- Load via CDN (`lottie-web@5.12.2/lottie.min.js`) or `import lottie from 'lottie-web'`. Renderer can be `svg` or `canvas`. Playback is controlled programmatically — `play()`, `pause()`, `stop()`, `setSpeed()`, `setDirection()`, `playSegments()`, and `goToAndStop(frame)` for scroll-scrubbed animation.
- Typical final artifact: a looping or interactive vector animation embedded in a page/app, driven by designer-authored After Effects content.

## Why
- Reach for Lottie when a *designer* authors the animation in After Effects and you need it to play faithfully and lightweightly across web and mobile — the JSON is small, resolution-independent, and controllable in code.
- Limitations: it is a playback framework, not an authoring or programmatic-animation tool — you don't write the motion in code, you export it from After Effects (via Bodymovin); complex AE effects can render inconsistently.
- Relative to siblings: lottie is the export-and-play outlier of this category — motion originates in a design tool rather than JavaScript. Choose it when the animation is design-driven and cross-platform; choose gsap/anime_js/mo_js when the animation is authored in code against live DOM/SVG elements.

## Source
- Solution reference: `fim/solution/lottie.md`
