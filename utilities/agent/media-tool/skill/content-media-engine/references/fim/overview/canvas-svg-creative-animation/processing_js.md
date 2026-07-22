# Processing.js

## What
A JavaScript port of the Processing creative-coding language, letting Processing-syntax sketches (`void setup()` / `void draw()`) run in the browser for 2D/3D graphics, interactive sketches, and animation loops. Its consumer is the browser canvas; output is animated/interactive canvas graphics.

## How
- The LLM emits either classic Processing syntax (`void setup(){ size(640,480); }`, `void draw(){ ellipse(mouseX, mouseY, 50, 50); }`) or the p5.js-style JS equivalent the source doc recommends as a modern path.
- Load the Processing.js bundle via CDN; the source doc explicitly points to p5.js (`p5.min.js`) as the modern alternative for new work. Sketches run as a `draw()` animation loop; `createCanvas(w, h, WEBGL)` enables 3D.
- Typical final artifact: a live 2D or 3D canvas sketch — generative art, particle/flow fields, mandalas, rotating 3D primitives.

## Why
- Reach for Processing.js when you are porting existing Processing sketches or want the familiar classic-Processing syntax in a web page for education or generative art.
- Limitations: it is effectively legacy — the source doc itself steers new projects toward p5.js — so it carries the tradeoff of an older, less-maintained runtime.
- Relative to siblings: processing_js is the classic-Processing-port option; p5.js is its modern successor. Prefer p5.js for anything new and reserve processing_js for compatibility with existing Processing-syntax code.

## Source
- Solution reference: `fim/solution/processing_js.md`
