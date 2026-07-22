# Rough.js

## What
A small library that renders graphics in a sketchy, hand-drawn aesthetic — shapes with configurable roughness, bowing, and hachure/zigzag/cross-hatch/dots fill patterns. It draws to either SVG or Canvas; its consumer is the browser.

## How
- The LLM emits Rough.js JavaScript that creates a renderer bound to a target and calls shape methods: `const rc = rough.canvas(canvas)` (or `rough.svg(svgEl)`), then `rc.rectangle(x,y,w,h, {fill, fillStyle, roughness, stroke})`, `rc.circle(...)`, `rc.path('M...Z', {...})`, `rc.polygon([...])`.
- Load via CDN (`unpkg.com/roughjs/bundled/rough.js`) or `import rough from 'roughjs'`. For SVG output, methods return DOM nodes you append (`svg.appendChild(rcSvg.rectangle(...))`); a `rough.generator()` produces reusable drawables.
- Typical final artifact: SVG or Canvas graphics with a deliberately hand-drawn look — sketchy charts, informal diagrams, annotations.

## Why
- Reach for Rough.js when the *look* matters: you want diagrams, charts, or shapes that read as hand-sketched/wireframe rather than crisp and mechanical. Style knobs (`roughness`, `bowing`, `fillStyle`, `hachureGap`, `fillWeight`) tune the effect.
- Limitations: it is a stylistic primitive-drawer, not an animation or scene-graph framework — no timeline, interaction, or retained-object model; you compose it with other tools for those.
- Relative to siblings: rough_js is the aesthetic specialist of this category. Where svg_js and paper_js render precise vectors, Rough.js exists specifically to make them look imperfect; pair it with the raw canvas-api or svg output when a sketchy visual identity is the goal.

## Source
- Solution reference: `fim/solution/rough_js.md`
