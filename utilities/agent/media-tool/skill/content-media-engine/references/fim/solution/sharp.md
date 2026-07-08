# Sharp — High-Performance Node.js Image Pipeline (libvips)

Sharp is a Node.js module for resizing, converting, compositing, and manipulating raster and vector-rasterized images. It wraps the C library **libvips**, giving it a low, near-constant memory footprint and throughput several times faster than ImageMagick or GraphicsMagick. Sharp is server-side only (native binaries); it renders JPEG, PNG, WebP, AVIF, TIFF, GIF, and rasterized SVG. The API is a lazy, chainable pipeline — nothing executes until you call an output method (`toFile`, `toBuffer`, or a stream `.pipe`).

**Current Version**: sharp@0.33.x (current major)  **License**: Apache-2.0  **Runtime**: Node.js ≥18.17, prebuilt libvips binaries bundled for common platforms (no system libvips required on install).

## Official Resources & Documentation
- Primary docs: https://sharp.pixelplumbing.com
- API constructor: https://sharp.pixelplumbing.com/api-constructor
- Resize reference: https://sharp.pixelplumbing.com/api-resize
- GitHub: https://github.com/lovell/sharp
- npm: https://www.npmjs.com/package/sharp
- libvips: https://www.libvips.org/

## Installation & Setup

### Package manager
```bash
npm install sharp
# pnpm add sharp   /   yarn add sharp
```

Prebuilt binaries cover macOS (x64/arm64), Linux glibc/musl (x64/arm64), and Windows x64. For cross-platform Docker or serverless bundling you may need to force a target:
```bash
npm install --os=linux --cpu=x64 sharp        # bundle Linux binaries from macOS
npm install --cpu=arm64 --os=linux sharp      # AWS Graviton / arm Lambda
```

### Import styles (ESM / CJS)
```javascript
import sharp from 'sharp';           // ESM (package is dual-published)
const sharp = require('sharp');      // CommonJS
```

### Input sources
```javascript
sharp('photo.jpg');                  // file path
sharp(buffer);                       // Buffer (fetched/uploaded bytes)
sharp({ create: {                    // generate a blank canvas
  width: 400, height: 300, channels: 4,
  background: { r: 255, g: 255, b: 255, alpha: 1 }
}});
sharp({ text: {                      // render text to an image (via Pango)
  text: '<span foreground="white">Hello</span>', rgba: true, width: 400, dpi: 150
}});
readStream.pipe(sharp().resize(200)); // stream in, stream out
```

## Core API Reference

The constructor returns a **Sharp instance**; chain operations, end with an output method. Operations are order-sensitive in the pipeline (resize before composite, etc.).

### Resize
```javascript
sharp('in.jpg').resize(300, 200, {
  fit: 'cover',        // cover | contain | fill | inside | outside
  position: 'centre',  // gravity or focal strategy: 'centre','north','attention','entropy'
  background: { r: 0, g: 0, b: 0, alpha: 0 }, // used by 'contain'
  withoutEnlargement: true,   // never upscale
  kernel: 'lanczos3'   // nearest | cubic | mitchell | lanczos2 | lanczos3
}).toFile('out.jpg');

sharp('in.jpg').resize({ width: 800 });        // width only, height auto (preserve aspect)
sharp('in.jpg').resize({ height: 400 });       // height only
```
`fit` semantics: **cover** crops to fill, **contain** letterboxes with `background`, **inside** fits within bounds (no crop, no upscale by default), **outside** covers bounds, **fill** ignores aspect ratio.

### Rotation, flip, affine
```javascript
sharp('in.jpg').rotate();               // auto-orient from EXIF (call BEFORE resize)
sharp('in.jpg').rotate(90);             // fixed degrees; arbitrary angle needs background
sharp('in.jpg').rotate(30, { background: '#ffffff' });
sharp('in.jpg').flip();                 // vertical mirror
sharp('in.jpg').flop();                 // horizontal mirror
sharp('in.jpg').affine([[1, 0.3], [0, 1]]); // shear/skew matrix
```

### Extract (crop) & extend (pad)
```javascript
sharp('in.jpg').extract({ left: 20, top: 30, width: 200, height: 150 });
sharp('in.jpg').extend({ top: 10, bottom: 10, left: 10, right: 10,
  background: { r: 0, g: 0, b: 0, alpha: 1 } });
// extract → resize → extract is legal; each extract acts on the current pipeline image.
sharp('in.jpg').resize(1000).extract({ left: 0, top: 0, width: 500, height: 500 });
```

### Composite (layering / watermarks)
```javascript
sharp('base.png').composite([
  { input: 'logo.png', gravity: 'southeast' },
  { input: 'overlay.png', top: 20, left: 20, blend: 'over' },
  { input: { create: { width: 100, height: 100, channels: 4,
      background: { r: 255, g: 0, b: 0, alpha: 0.4 } } }, tile: false }
]).toFile('out.png');
```
`blend` accepts Porter-Duff and photographic modes: `over`, `multiply`, `screen`, `overlay`, `darken`, `lighten`, `dest-in` (mask), `add`. `tile: true` repeats the overlay.

### Color & colorspace
```javascript
sharp('in.jpg')
  .grayscale()                        // alias greyscale()
  .tint({ r: 255, g: 240, b: 220 })   // multiply by a colour
  .modulate({ brightness: 1.1, saturation: 0.8, hue: 30 })
  .linear(1.2, -10)                   // a*input + b (contrast/brightness)
  .gamma(2.2)                         // 1.0–3.0 gamma correction
  .negate()                           // invert
  .normalise()                        // stretch contrast to full range
  .toColourspace('b-w');              // srgb | rgb16 | cmyk | b-w | lab
sharp('in.jpg').withMetadata({ icc: 'p3' }); // attach ICC profile on output
```

### Filters & effects
```javascript
sharp('in.jpg')
  .blur(3)                 // Gaussian sigma (0.3–1000); no arg = fast mild blur
  .sharpen({ sigma: 1.5 }) // unsharp mask; legacy .sharpen(sigma, flat, jagged)
  .median(3)               // noise reduction
  .threshold(128)          // binarize
  .clahe({ width: 8, height: 8 }); // contrast-limited adaptive histogram eq
```

### Channel operations
```javascript
sharp('in.png').removeAlpha();
sharp('in.jpg').ensureAlpha(0.5);
sharp('in.png').extractChannel('green');
sharp(['r.png','g.png','b.png']).joinChannel(['g.png','b.png']);
```

## Output Formats & Encoding Options

Each format method sets encoder options; call before an output sink. Omit the format method to infer from the `toFile` extension.

```javascript
sharp('in.png').jpeg({ quality: 80, progressive: true, mozjpeg: true, chromaSubsampling: '4:2:0' });
sharp('in.jpg').png({ compressionLevel: 9, palette: true, quality: 90, effort: 7 });
sharp('in.jpg').webp({ quality: 75, lossless: false, effort: 4, smartSubsample: true });
sharp('in.jpg').avif({ quality: 50, effort: 4, chromaSubsampling: '4:2:0' }); // best compression, slow
sharp('in.jpg').tiff({ compression: 'lzw', pyramid: true });
sharp('in.gif').gif({ colours: 128, dither: 1.0, loop: 0 });
sharp('in.svg').toFormat('png', { quality: 90 }); // generic form
```

### Output sinks
```javascript
const info = await sharp('in.jpg').resize(300).toFile('out.jpg'); // {format,width,height,size,...}
const buf  = await sharp('in.jpg').png().toBuffer();
const { data, info } = await sharp('in.jpg').raw().toBuffer({ resolveWithObject: true });
sharp('in.jpg').resize(300).pipe(res); // Sharp instance IS a duplex stream
```

### Metadata & stats (read without full decode)
```javascript
const meta = await sharp('in.jpg').metadata();  // {width,height,format,space,channels,hasAlpha,orientation,exif}
const stats = await sharp('in.jpg').stats();    // per-channel min/max/mean, dominant colour, isOpaque
```

## How-To (worked recipes)

### How to control color, format, and quality in one pipeline
```javascript
await sharp('portrait.png')
  .resize(1200, 1200, { fit: 'inside', withoutEnlargement: true })
  .modulate({ saturation: 1.05 })        // gentle colour pop
  .toColourspace('srgb')                 // normalise colourspace for web
  .avif({ quality: 55, effort: 4 })      // modern format, ~50% smaller than JPEG
  .toFile('portrait.avif');
```
Pick AVIF/WebP for web delivery; keep `quality` 45–60 for AVIF, 70–80 for WebP/JPEG. Higher `effort` = smaller file, slower encode.

### How to generate responsive image variants
```javascript
const src = sharp('hero.jpg').rotate();          // auto-orient once
for (const w of [320, 640, 960, 1280, 1920]) {
  await src.clone().resize({ width: w })
    .webp({ quality: 78 }).toFile(`hero-${w}.webp`);
}
```
Use `.clone()` so each variant branches from the same decoded source instead of re-reading the file.

### How to add a semi-transparent watermark
```javascript
const watermark = await sharp('logo.svg').resize(160).png().toBuffer();
await sharp('photo.jpg')
  .composite([{ input: watermark, gravity: 'southeast', blend: 'over' }])
  .jpeg({ quality: 82 })
  .toFile('watermarked.jpg');
```

### How to crop to a subject automatically
```javascript
await sharp('crowd.jpg')
  .resize(500, 500, { fit: 'cover', position: sharp.strategy.attention })
  .toFile('thumb.jpg'); // 'attention' targets high-detail/edge/skin regions; 'entropy' targets busiest region
```

### How to produce a flat thumbnail from a transparent PNG
```javascript
await sharp('icon.png')
  .flatten({ background: '#ffffff' })    // composite alpha onto white
  .resize(128, 128, { fit: 'contain', background: '#ffffff' })
  .png()
  .toFile('icon-thumb.png');
```

## Do's and Don'ts

### ✅ Do
- Call `.rotate()` (EXIF auto-orient) **before** `.resize()` so dimensions match the visible image.
- Reuse a decoded source with `.clone()` when emitting many sizes — avoids repeated disk reads.
- Prefer streams/buffers over temp files in request handlers: `sharp().resize(...).pipe(res)`.
- Set `failOn: 'none'` in the constructor when accepting user uploads that may be slightly malformed: `sharp(buf, { failOn: 'none' })`.
- Cap concurrency and pixel budgets under load: `sharp.concurrency(2)` and `sharp.cache(false)` for memory-tight workers.

### ❌ Don't
- Don't `await` the same instance twice — a Sharp instance is single-use per output. Build a new one or `.clone()`.
- Don't upscale silently; pass `withoutEnlargement: true` unless you intend to enlarge.
- Don't run Sharp in the browser — it needs native binaries. Use `jimp` or Canvas client-side.
- Don't decode giant images unbounded; libvips is streamed but a 100MP PNG still allocates. Guard with `metadata()` first.
- Don't forget `.flatten()` before JPEG output when the source has alpha — JPEG has no alpha and will fill black otherwise.

## Performance & Limits
- **Memory**: near-constant thanks to libvips demand-driven pipelines; large TIFFs benefit from `sequentialRead: true` on the constructor.
- **Concurrency**: libvips uses a thread pool; `sharp.concurrency(n)` bounds threads per operation, and multiple concurrent requests each spawn work — tune both.
- **Cache**: `sharp.cache({ memory: 50, files: 20, items: 100 })` or `sharp.cache(false)` to disable operation caching.
- **Animated formats**: pass `{ animated: true }` to the constructor to process all GIF/WebP frames; otherwise only frame 1.
- Pixel limit defaults to 0x3FFF x 0x3FFF; raise via `{ limitInputPixels: false }` only for trusted input.

## Common Pitfalls & Troubleshooting
- *Wrong orientation after resize* → you resized before `.rotate()`; reorder.
- *Black background on JPEG from PNG* → alpha lost; add `.flatten({ background })`.
- *`Input file contains unsupported image format`* → format not built into bundled libvips (e.g. some HEIC); confirm with `metadata()` and consider a system libvips with extra codecs.
- *Serverless "sharp: Command failed"* → binaries built for the wrong platform; reinstall with `--os`/`--cpu` flags matching the runtime.
- *Colours shift* → source has a non-sRGB ICC profile; call `.toColourspace('srgb')` and `.withMetadata()` to embed the profile.

## Best For / Avoid For
`server-image-pipeline`, `thumbnails`, `responsive-images`, `format-conversion`, `batch-optimization`, `watermarking` — choose Sharp for high-throughput Node backends and build steps.
Avoid for: browser/client-side work (use `jimp` or `canvas-api`), heavy vector authoring (use `svg_js`/`node-canvas`), or animation authoring.

## See Also
- `jimp.md` — pure-JS alternative that runs in the browser and serverless without native deps
- `node-canvas.md` — server-side drawing/compositing when you need a 2D drawing context
- `ffmpeg-wasm.md` — video/AV counterpart for media processing
- `../use-case/image-processing.md`
