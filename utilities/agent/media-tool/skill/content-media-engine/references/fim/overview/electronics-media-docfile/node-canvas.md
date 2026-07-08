# node-canvas

## What
node-canvas is a Cairo-backed implementation of the HTML Canvas API for Node.js, enabling server-side image generation and manipulation. Its primary consumer is Node.js server code; the LLM emits standard Canvas 2D drawing calls that render to an image buffer written to disk.

## How
- **LLM emits:** Canvas 2D API code using `createCanvas(w,h)` and a `ctx` — gradients, `fillRect`, `font`/`fillText`, `loadImage`, etc. — identical to browser Canvas usage.
- **Render path:** install native deps (`libcairo2-dev`, `libpango1.0-dev`, `libjpeg-dev`, `libgif-dev`, `librsvg2-dev`) then `npm install canvas`. Draw to the context, then `canvas.toBuffer('image/png')` and `fs.writeFileSync(...)`.
- **Typical final artifact:** PNG, JPEG, PDF, or SVG (via the Cairo backend).

## Why
- **Reach for it when:** you need to *generate* images from scratch server-side — dynamic charts/graphs, composited thumbnails, PDF reports with graphics, or batch image workflows — using the familiar Canvas API as a drop-in for browser code.
- **Limitations:** requires native Cairo dependencies with platform-specific builds, no WebGL context, memory-intensive on large images, and awkward deployment in containerized environments.
- **Relative to siblings:** node-canvas is the *drawing/compositing* tool of this media group (you paint pixels via Canvas), whereas Sharp/Jimp *transform* existing images — reach for node-canvas when the pixels don't exist yet and must be drawn.

## Source
- Solution reference: `fim/solution/node-canvas.md`
