# HTML5 Canvas 2D API — Native Browser Raster Drawing

The Canvas 2D API is the browser's built-in immediate-mode drawing surface. A `<canvas>` element plus a `CanvasRenderingContext2D` lets you draw shapes, paths, text, gradients, images, and per-pixel data, then animate via `requestAnimationFrame`. It is *immediate mode* — there is no retained scene graph; you clear and redraw each frame. This is the spec-level API reference for the context; the server-side twin with the same API is documented in `node-canvas.md`, and the declarative retained-mode alternative is `svg_js.md`.

**Spec**: HTML Living Standard (WHATWG) `CanvasRenderingContext2D`  **License**: web standard (no dependency)  **Runtime**: every modern browser; identical API on Node via node-canvas.

## Official Resources & Documentation
- MDN Canvas API: https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API
- Context reference: https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D
- Tutorial: https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial
- Spec: https://html.spec.whatwg.org/multipage/canvas.html

## Setup
```html
<canvas id="c" width="800" height="600"></canvas>
<script>
  const canvas = document.getElementById('c');
  const ctx = canvas.getContext('2d');        // or getContext('2d', { alpha: false })
  // Set the drawing buffer size (attributes, not CSS) to control resolution:
  canvas.width = 800; canvas.height = 600;
</script>
```
The `width`/`height` **attributes** set the pixel buffer; CSS `width`/`height` only stretch it. Mismatching them scales (and blurs) output.

### HiDPI / retina
```javascript
const dpr = window.devicePixelRatio || 1;
canvas.width = 800 * dpr; canvas.height = 600 * dpr;
canvas.style.width = '800px'; canvas.style.height = '600px';
ctx.scale(dpr, dpr);          // now draw in CSS pixels, render at device resolution
```

## Core API Reference

### Rectangles
```javascript
ctx.fillRect(x, y, w, h);       // filled
ctx.strokeRect(x, y, w, h);     // outlined
ctx.clearRect(x, y, w, h);      // erase to transparent
```

### Paths
```javascript
ctx.beginPath();
ctx.moveTo(x, y);
ctx.lineTo(x, y);
ctx.arc(cx, cy, r, startAngle, endAngle, counterclockwise);   // radians
ctx.arcTo(x1, y1, x2, y2, radius);
ctx.quadraticCurveTo(cpx, cpy, x, y);
ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
ctx.ellipse(cx, cy, rx, ry, rotation, start, end);
ctx.rect(x, y, w, h);
ctx.closePath();
ctx.fill();                     // fill current path ('evenodd' | 'nonzero')
ctx.stroke();                   // stroke current path
ctx.clip();                     // use path as clipping region
// Reusable geometry:
const p = new Path2D('M10 10 h 80 v 80 h -80 Z');
ctx.fill(p);
```

### Line style
```javascript
ctx.lineWidth = 4;
ctx.lineCap = 'round';          // butt | round | square
ctx.lineJoin = 'miter';         // miter | round | bevel
ctx.miterLimit = 10;
ctx.setLineDash([8, 4]);        // dashes/gaps
ctx.lineDashOffset = 2;
```

### Colours, gradients, patterns
```javascript
ctx.fillStyle = '#2b6cb0';                      // any CSS colour
ctx.strokeStyle = 'rgba(0,0,0,0.5)';
ctx.globalAlpha = 0.8;                          // 0–1 layer opacity

const lg = ctx.createLinearGradient(0, 0, 200, 0);
lg.addColorStop(0, 'red'); lg.addColorStop(1, 'blue');
ctx.fillStyle = lg;

const rg = ctx.createRadialGradient(100, 100, 0, 100, 100, 80);
const cg = ctx.createConicGradient(0, 100, 100);   // conic (newer browsers)
const pat = ctx.createPattern(image, 'repeat');    // repeat | repeat-x | repeat-y | no-repeat
```

### Compositing & shadows
```javascript
ctx.globalCompositeOperation = 'multiply';   // source-over(default), screen, overlay, lighter, destination-out, xor, ...
ctx.shadowColor = 'rgba(0,0,0,0.4)';
ctx.shadowBlur = 8; ctx.shadowOffsetX = 2; ctx.shadowOffsetY = 2;
ctx.filter = 'blur(3px) brightness(1.1)';    // CSS filter functions
```

### Text
```javascript
ctx.font = 'bold 32px Inter, sans-serif';
ctx.textAlign = 'center';         // start|end|left|right|center
ctx.textBaseline = 'middle';      // top|hanging|middle|alphabetic|ideographic|bottom
ctx.direction = 'ltr';
ctx.fillText('Hello', x, y, maxWidth);
ctx.strokeText('Outline', x, y);
const metrics = ctx.measureText('measure');   // width, actualBoundingBox*, fontBoundingBox*
```
Load web fonts before drawing: `await document.fonts.load('32px Inter')`.

### Images & video
```javascript
ctx.drawImage(img, dx, dy);
ctx.drawImage(img, dx, dy, dw, dh);
ctx.drawImage(img, sx, sy, sw, sh, dx, dy, dw, dh);   // source crop → dest rect
// img may be HTMLImageElement, HTMLCanvasElement, HTMLVideoElement, ImageBitmap, or OffscreenCanvas
ctx.imageSmoothingEnabled = false;      // nearest-neighbour for pixel art
ctx.imageSmoothingQuality = 'high';
```

### Transforms
```javascript
ctx.translate(dx, dy);
ctx.rotate(radians);
ctx.scale(sx, sy);
ctx.transform(a, b, c, d, e, f);        // multiply current matrix
ctx.setTransform(a, b, c, d, e, f);     // replace
ctx.resetTransform();
ctx.save(); /* ... */ ctx.restore();    // push/pop full drawing state
```

### Pixel data
```javascript
const imageData = ctx.getImageData(0, 0, w, h);   // { data: Uint8ClampedArray(RGBA), width, height }
for (let i = 0; i < imageData.data.length; i += 4) {
  imageData.data[i] = 255 - imageData.data[i];     // invert R
}
ctx.putImageData(imageData, 0, 0);
const blank = ctx.createImageData(w, h);
```

### Export
```javascript
canvas.toDataURL('image/png');
canvas.toDataURL('image/jpeg', 0.85);
canvas.toBlob(blob => { /* upload/download */ }, 'image/webp', 0.9);
const bitmap = canvas.transferToImageBitmap();     // OffscreenCanvas
```

## How-To (worked recipes)

### How to work with colour, gradients, and opacity
```javascript
ctx.fillStyle = '#0f172a'; ctx.fillRect(0, 0, 800, 600);   // background
const g = ctx.createLinearGradient(0, 0, 800, 0);
g.addColorStop(0, '#ff6b6b'); g.addColorStop(0.5, '#ffd93d'); g.addColorStop(1, '#4ecdc4');
ctx.fillStyle = g;
ctx.globalAlpha = 0.85;
ctx.fillRect(40, 40, 720, 120);
ctx.globalAlpha = 1;                                        // always reset
```

### How to run an animation loop
```javascript
let t = 0;
function frame() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);        // redraw from scratch
  const x = Math.sin(t) * 150 + 400;
  ctx.beginPath(); ctx.arc(x, 300, 30, 0, Math.PI * 2);
  ctx.fillStyle = '#4ecdc4'; ctx.fill();
  t += 0.03;
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
```

### How to draw crisp text on retina and measure it
```javascript
await document.fonts.load('bold 48px Inter');
ctx.font = 'bold 48px Inter';
const label = 'Dashboard';
const w = ctx.measureText(label).width;
ctx.fillStyle = '#111';
ctx.fillText(label, (canvas.width / (window.devicePixelRatio||1) - w) / 2, 80);
```

### How to apply a per-pixel filter (grayscale)
```javascript
const d = ctx.getImageData(0, 0, canvas.width, canvas.height);
for (let i = 0; i < d.data.length; i += 4) {
  const g = 0.299*d.data[i] + 0.587*d.data[i+1] + 0.114*d.data[i+2];
  d.data[i] = d.data[i+1] = d.data[i+2] = g;
}
ctx.putImageData(d, 0, 0);
```

## Do's and Don'ts

### ✅ Do
- Set `canvas.width/height` attributes (not CSS) to define resolution; scale by `devicePixelRatio` for sharpness.
- `clearRect` (or repaint the background) at the top of each animation frame — immediate mode retains nothing.
- Pair every `save()` with a `restore()`; leaking transform/clip state is the #1 canvas bug.
- Await `document.fonts.load(...)` before drawing text in a web font, or the first frame uses a fallback.
- Batch path building inside one `beginPath()` and a single `fill()`/`stroke()` for performance.

### ❌ Don't
- Don't forget to reset `globalAlpha`, `filter`, `shadowBlur`, and `globalCompositeOperation` — they persist across draws.
- Don't call `getImageData` per frame if avoidable — it forces a GPU→CPU readback and stalls.
- Don't animate by drawing over old frames without clearing (unless you want trails).
- Don't read pixels from a cross-origin image without CORS — the canvas becomes "tainted" and `toDataURL`/`getImageData` throw.
- Don't confuse angles: canvas arcs use **radians**, measured clockwise from the positive x-axis.

## Advanced Features
- **OffscreenCanvas** + Web Workers: render off the main thread (`canvas.transferControlToOffscreen()`).
- **Path2D**: build reusable geometry once, fill/stroke it many times.
- **`ctx.filter`**: CSS filter functions (blur, drop-shadow, hue-rotate) applied at draw time.
- **`isPointInPath` / `isPointInStroke`**: hit-testing for interactivity.
- **`createConicGradient`**: pie/gauge fills without manual arcs.

## Common Pitfalls & Troubleshooting
- *Blurry output* → drawing buffer smaller than CSS size, or no `devicePixelRatio` scaling.
- *`SecurityError` on `toDataURL`* → tainted canvas from a cross-origin image; serve with CORS and set `img.crossOrigin = 'anonymous'`.
- *Text is a box / wrong font* → web font not loaded before draw; `await document.fonts.ready`.
- *Everything shifts after a rotate* → unbalanced `save()/restore()`.
- *Half-pixel blur on 1px lines* → align to `x + 0.5` for odd stroke widths.

## Best For / Avoid For
`animation`, `games`, `data-viz-rendering`, `image-manipulation`, `pixel-effects`, `particle-systems`, `real-time-drawing` — the native choice for immediate-mode, high-FPS raster graphics.
Avoid for: retained/interactive vector scenes with many hit targets (use SVG/`svg_js`), print-quality vector export (SVG/PDF), or 3D (WebGL/`three.js`).

## See Also
- `node-canvas.md` — the same API on the server (Cairo), plus PNG/PDF/SVG export
- `svg_js.md` — retained-mode vector alternative (DOM nodes, easy hit-testing/animation)
- `html.md` — the page that hosts the `<canvas>`
- `../use-case/image-processing.md`
