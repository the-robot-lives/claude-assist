# GSAP (GreenSock Animation Platform)

## What
A professional-grade JavaScript animation platform for high-performance tweening and timeline sequencing, with a large plugin ecosystem (ScrollTrigger, MorphSVG, DrawSVG, and more). Its consumer is the browser DOM/SVG; output is animations of existing page elements.

## How
- The LLM emits GSAP JavaScript built around tweens and timelines: `gsap.to('.box', { x: 200, rotation: 360, duration: 2, ease: 'power2.inOut' })`, `gsap.timeline({repeat:-1, yoyo:true})` chaining `.to(...)` with relative position labels, and staggered/`fromTo` variants.
- Load via CDN (`gsap@3.12.2/gsap.min.js`) or `import { gsap } from 'gsap'`; plugins are registered explicitly, e.g. `import { ScrollTrigger } from 'gsap/ScrollTrigger'; gsap.registerPlugin(ScrollTrigger)`. ScrollTrigger binds animations to scroll position with `scrub`.
- Typical final artifact: animated DOM/SVG on a live page — scroll-driven parallax, grid staggers, SVG morphing/drawing, complex sequenced motion.

## Why
- Reach for GSAP when the animation work is demanding: precise timeline orchestration, scroll-triggered effects, SVG morph/draw, grid staggers, and rock-solid cross-browser performance — the go-to for production-grade, complex motion.
- Limitations (per its category context): it is heavier and more feature-dense than the minimalist libraries, and its premium plugins (MorphSVG, DrawSVG, etc.) sit behind GreenSock's licensing.
- Relative to siblings: gsap is the full-featured, commercial-grade end of the spectrum; anime_js is the lightweight free counterpart. Choose gsap when you need timeline depth, ScrollTrigger, and the plugin suite; choose anime_js, velocity_js, or mo_js when a small, simple library covers the need.

## Source
- Solution reference: `fim/solution/gsap.md`
