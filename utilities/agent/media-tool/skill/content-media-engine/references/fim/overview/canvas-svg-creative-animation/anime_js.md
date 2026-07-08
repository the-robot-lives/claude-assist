# Anime.js

## What
A lightweight (~14KB, MIT, no dependencies) JavaScript animation library with a simple but powerful API that animates CSS properties, SVG, DOM attributes, and plain JavaScript objects. Its consumer is the browser DOM/SVG; output is timeline-driven animations of existing page elements.

## How
- The LLM emits Anime.js JavaScript that describes tweens declaratively: `anime({ targets: '.box', translateX: 250, rotate: 360, duration: 2000, easing: 'easeInOutQuad' })`, plus keyframes, staggering, and `anime.timeline(...)` for orchestrated sequences.
- Install with `npm install animejs` (`import anime from 'animejs/lib/anime.es.js'`) or a CDN script (`animejs@3.2.1/lib/anime.min.js`); an ES-module CDN import is also available. It uses `requestAnimationFrame` internally for 60fps playback and supports SVG path drawing/morphing.
- Typical final artifact: animated DOM/SVG on a live page — UI motion, SVG line-drawing, staggered reveals, sequenced timelines.

## Why
- Reach for Anime.js when you want a small, framework-agnostic library for rich property/SVG/timeline animation with minimal code: 30+ easings, precise timeline control, first-class SVG, and a gentle learning curve.
- Limitations: no built-in physics engine (springs/gravity/collisions), limited Canvas/WebGL support, no native audio sync or gesture handling, and it can be overkill for trivial fade/slide effects; React lifecycle integration needs care.
- Relative to siblings: anime_js is the lightweight-but-capable middle ground — more structured than velocity_js/mo_js, lighter and free versus gsap. Choose gsap instead when you need commercial-grade timeline control, ScrollTrigger, and heavy-duty plugins; choose anime_js when a compact dependency-free tween/timeline library is enough.

## Source
- Solution reference: `fim/solution/anime_js.md`
