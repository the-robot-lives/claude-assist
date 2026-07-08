# node-canvas — Server-Side Canvas 2D (Cairo-backed)

node-canvas is a Node.js implementation of the HTML5 Canvas API backed by **Cairo**. It gives the server the same `getContext('2d')` drawing surface a browser exposes, so code that draws shapes, text, gradients, images, and paths runs unchanged on the backend — then exports to PNG, JPEG, PDF, or SVG. Use it to generate social cards, dynamic charts, badges, thumbnails, and report graphics without a headless browser. It needs native Cairo/Pango system libraries at install time.

**Current Version**: canvas@2.11.x / 3.x (current)  **License**: MIT  **Runtime**: Node.js with native Cairo, Pango, and image libs.

## Official Resources & Documentation
- GitHub: https://github.com/Automattic/node-canvas
- npm: https://www.npmjs.com/package/canvas
- Canvas 2D API (semantics are identical): https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D

## Installation & Setup

### System dependencies
```bash
# Debian/Ubuntu
sudo apt-get install build-essential libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev
# macOS (Homebrew)
brew install pkg-config cairo pango libpng jpeg giflib librsvg
```

### Package
```bash
npm install canvas
```

### Import styles
```javascript
const { createCanvas, loadImage, registerFont, Image } = require('canvas');   // CJS
import { createCanvas, loadImage, registerFont } from 'canvas';               // ESM
```

## Core API Reference

### Creating a surface
```javascript
const canvas = createCanvas(800, 600);              // raster (PNG/JPEG)
const pdf    = createCanvas(800, 600, 'pdf');       // vector PDF surface
const svg    = createCanvas(800, 600, 'svg');       // SVG surface
const ctx = canvas.getContext('2d');
```

### Drawing (standard Canvas 2D — see canvas-api.md for the full surface)
```javascript
ctx.fillStyle = '#2b6cb0';
ctx.fillRect(0, 0, 800, 120);
ctx.strokeStyle = '#1a365d'; ctx.lineWidth = 4;
ctx.strokeRect(20, 140, 200, 100);

ctx.beginPath();
ctx.arc(400, 300, 80, 0, Math.PI * 2);
ctx.fillStyle = '#4ecdc4'; ctx.fill();

ctx.beginPath();
ctx.moveTo(600, 200); ctx.lineTo(700, 260); ctx.lineTo(620, 340); ctx.closePath();
ctx.fillStyle = '#ff6b6b'; ctx.fill();
```

### Gradients & patterns
```javascript
const grad = ctx.createLinearGradient(0, 0, 800, 0);
grad.addColorStop(0, '#ff6b6b'); grad.addColorStop(1, '#4ecdc4');
ctx.fillStyle = grad; ctx.fillRect(0, 400, 800, 120);

const radial = ctx.createRadialGradient(400, 300, 0, 400, 300, 200);
radial.addColorStop(0, '#fff'); radial.addColorStop(1, '#333');

const tile = await loadImage('tile.png');
ctx.fillStyle = ctx.createPattern(tile, 'repeat');
```

### Images
```javascript
const img = await loadImage('photo.jpg');           // path, URL, Buffer, or data URI
ctx.drawImage(img, 50, 50, 300, 200);
ctx.drawImage(img, sx, sy, sw, sh, dx, dy, dw, dh); // source-crop form
```

### Text & fonts
```javascript
registerFont('fonts/Inter-Bold.ttf', { family: 'Inter', weight: 'bold' }); // BEFORE createCanvas
ctx.font = 'bold 48px Inter';
ctx.fillStyle = 'white';
ctx.textAlign = 'center';        // start|end|left|right|center
ctx.textBaseline = 'middle';     // top|hanging|middle|alphabetic|ideographic|bottom
ctx.fillText('Server-Side Canvas', 400, 60);
const m = ctx.measureText('width?');   // { width, actualBoundingBoxAscent, ... }
```

### Transforms & state
```javascript
ctx.save();
ctx.translate(400, 300); ctx.rotate(Math.PI / 6); ctx.scale(1.2, 1.2);
ctx.fillRect(-50, -50, 100, 100);
ctx.restore();
```

## Output Formats & Export
```javascript
// PNG
fs.writeFileSync('out.png', canvas.toBuffer('image/png'));
// JPEG with quality
fs.writeFileSync('out.jpg', canvas.toBuffer('image/jpeg', { quality: 0.8 }));
// PDF (create the canvas with 'pdf'); add pages before the final buffer
const pdfCtx = pdf.getContext('2d'); /* draw */ pdf.toBuffer(); // 'application/pdf'
// SVG (create the canvas with 'svg')
fs.writeFileSync('out.svg', svg.toBuffer());   // 'image/svg+xml'
// Streaming (large images, avoids buffering)
const out = fs.createWriteStream('big.png');
canvas.createPNGStream().pipe(out);
canvas.createJPEGStream({ quality: 0.85 }).pipe(out);
// data URI
const uri = canvas.toDataURL('image/png');
```

### Multi-page PDF
```javascript
const doc = createCanvas(595, 842, 'pdf');       // A4 in points
const c = doc.getContext('2d');
c.fillText('Page 1', 40, 60);
c.addPage();                                     // node-canvas PDF extension
c.fillText('Page 2', 40, 60);
fs.writeFileSync('report.pdf', doc.toBuffer());
```

## How-To (worked recipes)

### How to control colour, gradients, and quality on export
```javascript
const canvas = createCanvas(1200, 630);
const ctx = canvas.getContext('2d');
const bg = ctx.createLinearGradient(0, 0, 1200, 630);
bg.addColorStop(0, '#0f172a'); bg.addColorStop(1, '#334155');
ctx.fillStyle = bg; ctx.fillRect(0, 0, 1200, 630);
ctx.fillStyle = '#f8fafc'; ctx.font = 'bold 64px Inter';
ctx.fillText('Release Notes', 80, 340);
fs.writeFileSync('card.jpg', canvas.toBuffer('image/jpeg', { quality: 0.9 })); // quality 0–1
```

### How to generate a dynamic social/OG image
```javascript
registerFont('fonts/Inter-Bold.ttf', { family: 'Inter', weight: '700' });
const canvas = createCanvas(1200, 630);
const ctx = canvas.getContext('2d');
ctx.fillStyle = '#111827'; ctx.fillRect(0, 0, 1200, 630);
const avatar = await loadImage(avatarUrl);
ctx.save(); ctx.beginPath(); ctx.arc(140, 140, 60, 0, Math.PI*2); ctx.clip();
ctx.drawImage(avatar, 80, 80, 120, 120); ctx.restore();
ctx.fillStyle = '#fff'; ctx.font = '700 52px Inter';
ctx.fillText(title, 80, 360, 1040);           // maxWidth clamps
return canvas.toBuffer('image/png');
```

### How to render an SVG asset onto the canvas
```javascript
const svgImg = await loadImage(Buffer.from('<svg .../>'));  // requires librsvg
ctx.drawImage(svgImg, 0, 0);
```

### How to export vector PDF for print
```javascript
const doc = createCanvas(612, 792, 'pdf');     // US Letter, points
const c = doc.getContext('2d');
c.font = '20px Inter'; c.fillText('Invoice #1042', 40, 60);
c.strokeRect(40, 80, 532, 400);
fs.writeFileSync('invoice.pdf', doc.toBuffer());
```

## Do's and Don'ts

### ✅ Do
- Call `registerFont()` **before** `createCanvas()` — fonts registered afterward are ignored.
- Stream large PNG/JPEG output (`createPNGStream().pipe`) to keep memory flat.
- Create the canvas with `'pdf'`/`'svg'` type when you need vector output; the raster methods won't produce vectors.
- Pre-scale/crop with `drawImage`'s 9-argument form instead of resizing whole images in memory.

### ❌ Don't
- Don't expect **WebGL** — node-canvas is 2D only. For 3D server rendering you need a headless GL stack.
- Don't skip system deps — install fails without Cairo/Pango dev headers; containers need them in the image.
- Don't register a font and then reference the wrong `family` string in `ctx.font` — they must match exactly.
- Don't assume browser-only APIs exist (no `document`, no DOM events); it's the drawing context, nothing more.

## Deployment Notes
- **Docker**: base the image on one with Cairo/Pango, or `apt-get install` the libs in the build stage; Alpine needs the `cairo pango jpeg giflib` musl packages plus build tools.
- **Serverless**: heavy native deps make Lambda packaging awkward; prefer a container image or a prebuilt layer. Consider a pure-WASM canvas (e.g. `@napi-rs/canvas`, `skia-canvas`) if native builds are a blocker.
- **Fonts in containers**: ship the `.ttf`/`.otf` files and `registerFont` them; system font fallbacks are minimal in slim images.

## Common Pitfalls & Troubleshooting
- *Text renders in a fallback font* → font not registered before `createCanvas`, or `family` mismatch.
- *Install fails* → missing Cairo/Pango/pkg-config; install the system dev packages.
- *SVG `loadImage` fails* → librsvg not installed.
- *Blurry output* → draw at 2× dimensions for HiDPI, or increase canvas size and downscale on export.
- *PDF has one page only* → use `c.addPage()` between pages on a `'pdf'` canvas.

## Best For / Avoid For
`server-image-generation`, `og-social-cards`, `dynamic-charts`, `thumbnails`, `pdf/svg-export`, `batch-graphics` — the standard for Canvas-style drawing on Node.
Avoid for: 3D/WebGL, browser-side work (use the native `canvas-api`), or high-volume photo resizing (use `sharp`).

## See Also
- `canvas-api.md` — the identical 2D drawing API in the browser (spec-level reference)
- `sharp.md` — faster path for pure photo resize/convert
- `svg_js.md` — build SVG you can `drawImage` onto the canvas
- `../use-case/image-processing.md`, `../use-case/document-generation.md`
