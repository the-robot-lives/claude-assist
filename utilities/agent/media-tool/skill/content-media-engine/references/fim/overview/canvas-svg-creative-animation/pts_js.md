# Pts.js

## What
A visualization and creative-coding library organized around point-based geometry — Points (`Pt`), Groups, Forms, and Spaces — with creative-math utilities and physics helpers. It renders to Canvas or SVG; its consumer is the browser.

## How
- The LLM emits Pts.js JavaScript that sets up a space and animates it: `const space = new CanvasSpace("#canvas").setup({bgcolor:"#000"})`, `const form = space.getForm()`, then `space.add({ animate: (time, ftime) => { ... } })` and `space.play()`.
- Load via CDN (`pts.min.js`) or import named members (`import { CanvasSpace, Pt, Group, Circle, Line } from 'pts'`). Drawing happens inside the `animate` callback through the `form` (e.g. `form.fillOnly("#fff").circle(...)`); geometry ops and a `World` physics helper are available.
- Typical final artifact: an animated Canvas (or SVG) visualization — particle systems, wave forms, spirals, Voronoi/Delaunay, physics bodies.

## Why
- Reach for Pts.js when the work is fundamentally geometric/point-driven: math-heavy creative coding, generative patterns, and light physics where treating everything as points and groups is natural.
- Limitations: smaller ecosystem than p5.js; the point/Group/Form/Space abstraction is a specific mental model to learn (the source doc frames its value around those core concepts rather than broad feature breadth).
- Relative to siblings: pts_js occupies the same creative-coding niche as p5.js but with a distinctive point-geometry and typed-space API and dual Canvas/SVG output; choose it when geometric composition is the point, p5.js when you want the larger community and immediate-mode familiarity.

## Source
- Solution reference: `fim/solution/pts_js.md`
