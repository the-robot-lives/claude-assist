# 2D Canvas / SVG / Creative Coding + Animation

These solutions produce and animate 2D graphics for the browser — from raw drawing primitives and vector/creative-coding frameworks to dedicated motion engines. The shared consumer pattern is a browser surface (Canvas, SVG DOM, or WebGL): the LLM emits JavaScript (or, for MetaPost, a compiled figure language) that either draws shapes or animates existing page elements, rendered live rather than exported as a static file.

## Solutions

#### 2D Canvas / SVG / Creative Coding

### HTML5 Canvas API
The native browser 2D drawing API (`getContext('2d')`) — immediate-mode rectangles, arcs, paths, text, gradients, and direct pixel access, with no dependency. You issue draw calls each frame in a `requestAnimationFrame` loop; output is a raster canvas bitmap. The bare-metal substrate the other canvas libraries build on — pick it for zero dependencies, pixel manipulation, or small performance-critical work. [Detail](canvas-svg-creative-animation/canvas-api.md)

### Paper.js
An MIT vector-graphics framework for the HTML5 Canvas, built on a retained scene graph with bezier paths, boolean path operations (union/intersect/subtract), symbols, and layers. Bind a canvas with `paper.setup()`, construct `paper.Path` objects, animate via `view.onFrame`. Pick it over the raw API when you need vector objects and boolean/bezier geometry math. [Detail](canvas-svg-creative-animation/paper_js.md)

### p5.js
The modern JS creative-coding standard — an immediate-mode `setup()`/`draw()` library with easy input handling and optional WebGL 3D. Emit a sketch; the `draw()` loop runs continuously against the canvas. Best for generative art, installations, and education; choose it over Processing.js for idiomatic modern JS and an active ecosystem. [Detail](canvas-svg-creative-animation/p5_js.md)

### Processing.js
A JavaScript port of the classic Processing language, running `void setup()`/`void draw()` sketches in the browser. Effectively legacy — its own source doc steers new work toward p5.js. Reach for it only to port existing Processing-syntax sketches; otherwise prefer p5.js. [Detail](canvas-svg-creative-animation/processing_js.md)

### Pts.js
A creative-coding library built on point-based geometry — Points, Groups, Forms, and Spaces — with creative-math and light physics helpers, rendering to Canvas or SVG. Set up a `CanvasSpace`, draw inside its `animate` callback via a `form`. Pick it when geometric composition is the point; p5.js when you want the larger community. [Detail](canvas-svg-creative-animation/pts_js.md)

### Rough.js
A small library that renders shapes in a deliberately hand-drawn, sketchy aesthetic (configurable roughness, bowing, hachure/cross-hatch fills), to SVG or Canvas. Create a renderer bound to a target and call shape methods. The category's aesthetic specialist — use it when a wireframe/hand-sketched look is the goal, paired with other drawing tools. [Detail](canvas-svg-creative-animation/rough_js.md)

### SVG.js
A lightweight library for creating, manipulating, and animating SVG through a chainable DOM API, with gradients, patterns, masks, events, and a timeline. Output is live, resolution-independent SVG elements. Pick it when you specifically want SVG DOM (crisp, inspectable, CSS-stylable) rather than canvas, without needing boolean path math. [Detail](canvas-svg-creative-animation/svg_js.md)

### Two.js
A 2D drawing library with one unified API that renders to SVG, Canvas, or WebGL interchangeably, over a scene graph with a built-in animation loop. Construct a `Two` instance, `makeCircle`/`makePath`, animate via `bind('update')`. Pick it when backend flexibility matters and you don't need boolean geometry. [Detail](canvas-svg-creative-animation/two_js.md)

### MetaPost
A TeX-ecosystem graphics *language* for precise, resolution-independent figures via declarative paths, transformations, and math plotting. Emit a `.mp` program, compile with `mpost`, convert to SVG through a PDF step. The print/LaTeX-oriented outlier — choose it for publication-quality technical figures in documents, not the web. [Detail](canvas-svg-creative-animation/metapost.md)

### Spline
A no-code 3D design tool plus web runtime: scenes are authored visually in the Spline editor and embedded/controlled via a JS API (`Application.load(...)` of a `.splinecode` asset), with a React wrapper. The editor-first 3D outlier — choose it for polished interactive 3D embeds when visual authoring beats code-level scene control. [Detail](canvas-svg-creative-animation/spline.md)

#### Animation & Motion

### Anime.js
A lightweight (~14KB, MIT, zero-dependency) engine that animates CSS, SVG, DOM attributes, and JS objects via a declarative `anime({targets, ...})` API with keyframes, staggering, and timelines. The capable middle ground — lighter and free versus GSAP, more structured than Velocity/Mo.js. Choose it when a compact tween/timeline library suffices. [Detail](canvas-svg-creative-animation/anime_js.md)

### GSAP (GreenSock)
A professional-grade platform for high-performance tweening and timeline sequencing, with a large plugin ecosystem (ScrollTrigger, MorphSVG, DrawSVG). Emit `gsap.to(...)` tweens and `gsap.timeline(...)` sequences; register plugins explicitly. The full-featured, commercial-grade end of the spectrum — pick it for demanding timelines, scroll effects, and SVG morph/draw. [Detail](canvas-svg-creative-animation/gsap.md)

### Lottie
A framework that plays After Effects animations natively on web and mobile from Bodymovin-exported JSON. Emit player integration (`lottie.loadAnimation({container, path})`); control via `play`/`goToAndStop` for scroll-scrubbing. The export-and-play outlier — motion originates in a design tool, not code. Choose it when animations are designer-authored and cross-platform. [Detail](canvas-svg-creative-animation/lottie.md)

### Mo.js
A declarative motion-graphics library specializing in shape animation, custom SVG shapes, motion paths, and particle "burst" effects, using a `{from: to}` property syntax. The motion-graphics/effects specialist — pick it for bursts and custom-shape spectacle rather than general element tweening. [Detail](canvas-svg-creative-animation/mo_js.md)

### Velocity.js
A fast animation engine with jQuery-like syntax, hardware acceleration, color/SVG animation, pre-built transition effects, and scroll motion (`Velocity(el, {props}, {opts})`). The familiar, effects-and-transitions option — pick it for straightforward UI transitions; move to GSAP when you outgrow it into complex timelines. [Detail](canvas-svg-creative-animation/velocity_js.md)

## Choosing within this category

- **Raw control / pixels** → HTML5 Canvas API. **Vector scene graph on canvas** → Paper.js. **Renderer-agnostic shapes** → Two.js. **SVG DOM specifically** → SVG.js.
- **Creative coding / generative art** → p5.js (modern), Pts.js (point-geometry), Processing.js (legacy port only).
- **Aesthetic (hand-drawn)** → Rough.js. **Print/LaTeX figures** → MetaPost. **No-code 3D embeds** → Spline.
- **Animating existing elements**: GSAP (heavy-duty, commercial) → Anime.js (light, free) → Velocity.js (jQuery-style UI transitions). **Motion-graphics effects** → Mo.js. **Designer-authored playback** → Lottie.
