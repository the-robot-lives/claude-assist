# Velocity.js

## What
A high-performance animation engine with jQuery-like syntax, featuring hardware acceleration, color and SVG animation, pre-built transition effects, and scroll animation. Its consumer is the browser DOM/SVG; output is animations of existing page elements.

## How
- The LLM emits Velocity.js JavaScript that animates an element toward a property set: `Velocity(el, { translateX: '200px', rotateZ: '45deg', opacity: 0.5 }, { duration: 1000, easing: 'easeInOutQuad' })`, with promise-chained sequences (`.then(() => Velocity(...))`) and named effects like `Velocity(el, 'fadeIn')` or `Velocity(el, 'transition.slideUpIn')`.
- Load via CDN (`velocity/2.0.6/velocity.min.js`) or `import Velocity from 'velocity-animate'`. It animates colors, SVG stroke properties, and supports `Velocity(el, 'scroll', {...})` for scroll-to motion and `{loop: true}` for repeats.
- Typical final artifact: animated DOM/SVG on a live page — UI entrance/exit transitions, attention cues, scroll motion, staggered sequences.

## Why
- Reach for Velocity.js when you want fast, familiar jQuery-style animation with ready-made transition effects and easy chaining — well suited to UI micro-interactions and page transitions without a large timeline framework.
- Limitations (per its category context): it is a general element-animation engine without a deep timeline-orchestration or plugin ecosystem, and its jQuery-era idiom is dated relative to newer libraries.
- Relative to siblings: velocity_js is the jQuery-flavored, effects-and-transitions option. Choose it for straightforward UI transitions with a familiar API; choose gsap when you outgrow it into complex timelines/ScrollTrigger, or anime_js for a similarly light but more modern object-based API.

## Source
- Solution reference: `fim/solution/velocity_js.md`
