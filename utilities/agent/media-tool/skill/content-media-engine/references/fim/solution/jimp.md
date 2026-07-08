# Jimp — Pure-JavaScript Image Processing (zero native deps)

Jimp ("JavaScript Image Manipulation Program") is an image-processing library written entirely in JavaScript with **no native bindings**. That makes it the go-to when Sharp's native binaries are unavailable — browsers, edge/serverless runtimes, or environments where you can't compile libvips. It reads and writes PNG, JPEG, BMP, TIFF, and GIF, and offers a chainable API for resize, crop, colour adjustment, filters, compositing, and text. The trade-off is speed and memory: it decodes to a raw RGBA bitmap in memory, so it is markedly slower than Sharp on large images.

**Current Version**: jimp@1.6.x (current major — full ESM/TypeScript rewrite)  **License**: MIT  **Runtime**: Node.js ≥18 and browsers (bundled build).

> The v1 rewrite changed the API from the long-lived v0.x. This doc targets **v1**; a migration note at the end maps the old calls.

## Official Resources & Documentation
- Docs: https://jimp-dev.github.io/jimp/
- GitHub: https://github.com/jimp-dev/jimp
- npm: https://www.npmjs.com/package/jimp

## Installation & Setup

### Package manager
```bash
npm install jimp
```

### Import styles
```javascript
import { Jimp } from 'jimp';               // ESM / TypeScript (v1)
const { Jimp } = require('jimp');          // CJS interop
```

### Browser
```html
<script type="module">
  import { Jimp } from 'https://cdn.jsdelivr.net/npm/jimp@1/dist/browser/index.js';
  const image = await Jimp.read('/photo.jpg');
</script>
```

## Core API Reference

Jimp is promise-based. `Jimp.read()` resolves to an image instance; methods mutate and return `this` for chaining; output methods are async.

### Loading & creating
```javascript
const image = await Jimp.read('input.jpg');        // path, URL, Buffer, or ArrayBuffer
const blank = new Jimp({ width: 400, height: 300, color: 0xffffffff }); // RGBA int
const fromBuf = await Jimp.fromBuffer(buffer);
```

### Geometry
```javascript
image.resize({ w: 256, h: 256 });     // omit one of w/h to auto-scale (use Jimp.AUTO in v0)
image.scale(0.5);                      // factor
image.cover({ w: 300, h: 200 });       // resize + crop to fill
image.contain({ w: 300, h: 200 });     // resize + letterbox to fit
image.crop({ x: 10, y: 10, w: 100, h: 100 });
image.rotate(45);                      // degrees, expands canvas
image.flip({ horizontal: true, vertical: false });
```

### Colour & tone
```javascript
image.greyscale();                     // alias grayscale()
image.sepia();
image.invert();
image.brightness(0.2);                 // -1 .. 1
image.contrast(0.3);                   // -1 .. 1
image.opacity(0.5);                    // scale alpha 0 .. 1
image.color([                          // stacked colour transforms
  { apply: 'hue', params: [90] },
  { apply: 'lighten', params: [20] },
  { apply: 'desaturate', params: [30] }
]);
```

### Filters & effects
```javascript
image.blur(5);          // fast box-ish blur, radius px
image.gaussian(3);      // true Gaussian (slow)
image.posterize(8);     // reduce colour levels
image.pixelate(10);     // mosaic
image.dither();         // Floyd–Steinberg-style dithering
image.normalize();      // stretch contrast
```

### Compositing & masking
```javascript
const logo = await Jimp.read('logo.png');
image.composite(logo, 20, 20, {                 // x, y, options
  mode: 'srcOver',                              // blend mode
  opacitySource: 0.8, opacityDest: 1
});
image.mask(maskImage, 0, 0);                    // alpha mask from another image
```

### Text (font plugin)
```javascript
import { loadFont } from 'jimp/fonts';
import { SANS_32_BLACK } from '@jimp/plugin-print/fonts';

const font = await loadFont(SANS_32_BLACK);
image.print({ font, x: 10, y: 10, text: 'Caption' });
image.print({ font, x: 10, y: 60,
  text: { text: 'Centered', alignmentX: 1 }, maxWidth: 300 });
```
Jimp ships bitmap fonts (BMFont). For custom typefaces, generate a `.fnt` atlas.

### Pixel access
```javascript
const hex = image.getPixelColor(x, y);          // 0xRRGGBBAA integer
image.setPixelColor(0xff0000ff, x, y);
image.scan(0, 0, image.width, image.height, (x, y, idx) => {
  image.bitmap.data[idx + 0] = 255 - image.bitmap.data[idx + 0]; // R
  image.bitmap.data[idx + 1] = 255 - image.bitmap.data[idx + 1]; // G
  image.bitmap.data[idx + 2] = 255 - image.bitmap.data[idx + 2]; // B
});
```

### Output
```javascript
await image.write('output.png');                 // extension picks encoder
const png  = await image.getBuffer('image/png');
const jpg  = await image.getBuffer('image/jpeg', { quality: 60 });
const uri  = await image.getBase64('image/png'); // data: URI for <img src>
```

## Supported Formats
Read/write: **PNG, JPEG, BMP, TIFF, GIF** (GIF write via plugin). MIME strings replace v0 constants: `'image/png'`, `'image/jpeg'`, `'image/bmp'`, `'image/tiff'`, `'image/gif'`.

## How-To (worked recipes)

### How to adjust colour, apply a filter, and set output quality
```javascript
const image = await Jimp.read('input.jpg');
image
  .color([{ apply: 'saturate', params: [15] }])  // +15% saturation
  .brightness(0.05)
  .gaussian(1);
await image.getBuffer('image/jpeg', { quality: 70 })
  .then(buf => fs.promises.writeFile('out.jpg', buf));
```
`color()` stacks named ops (`hue`, `lighten`, `darken`, `saturate`, `desaturate`, `tint`, `shade`, `mix`), each with numeric params.

### How to build a square avatar thumbnail in the browser
```javascript
const image = await Jimp.read(fileObjectUrl);
image.cover({ w: 128, h: 128 });                 // fill 128×128, cropping overflow
document.querySelector('img').src = await image.getBase64('image/png');
```

### How to watermark with a semi-transparent overlay
```javascript
const base = await Jimp.read('photo.jpg');
const mark = await Jimp.read('logo.png');
mark.opacity(0.5);
base.composite(mark, base.width - mark.width - 16, base.height - mark.height - 16);
await base.write('watermarked.jpg');
```

### How to convert a batch of PNGs to compressed JPEG
```javascript
for (const file of await fs.promises.readdir('src')) {
  if (!file.endsWith('.png')) continue;
  const img = await Jimp.read(`src/${file}`);
  img.background(0xffffffff);                     // flatten transparency to white
  await img.getBuffer('image/jpeg', { quality: 75 })
    .then(b => fs.promises.writeFile(`out/${file.replace('.png','.jpg')}`, b));
}
```

## Do's and Don'ts

### ✅ Do
- Use Jimp when you need **browser or dependency-free** processing; that's its reason to exist.
- Flatten alpha with `.background(0xffffffff)` before JPEG output — JPEG has no transparency.
- Reach for `.scan()` / `getPixelColor` when you need per-pixel logic (heatmaps, chroma-key, custom filters).
- Downscale early in the chain so later ops run on fewer pixels.

### ❌ Don't
- Don't use Jimp for high-volume server pipelines or very large images — prefer `sharp` (10×+ faster, far less memory).
- Don't rely on v0 constants (`Jimp.MIME_PNG`, `Jimp.AUTO`) in v1 — use MIME strings and omit a dimension instead.
- Don't forget these methods **mutate** the instance; `clone()` first if you need the original.
- Don't expect chained ops to be lazy — each call executes immediately on the in-memory bitmap.

## Styling & Colour Model
Pixels are RGBA stored as a `0xRRGGBBAA` 32-bit integer or as bytes in `image.bitmap.data` (Uint8, R,G,B,A per pixel). Helpers: `Jimp.rgbaToInt(r,g,b,a)` and `Jimp.intToRGBA(int)`. Blend modes for `composite`: `srcOver`, `add`, `multiply`, `screen`, `overlay`, `darken`, `lighten`, `hardLight`, `difference`, `exclusion`.

## Common Pitfalls & Troubleshooting
- *Slow / high memory on big images* → expected; decode is JS. Cap dimensions or switch to Sharp.
- *`write is not a function` / type error on path* → v1 `write()` requires a `name.ext` string literal type in TS; cast or ensure the extension is present.
- *Transparent areas turn black in JPEG* → flatten with a background first.
- *Fonts don't render* → you must `loadFont()` an async bitmap font before `print()`; there is no default font.
- *GIF won't save* → ensure the GIF plugin is present (bundled in v1's default `jimp` package).

## Migration: v0.x → v1.x
```javascript
// v0
const Jimp = require('jimp');
const img = await Jimp.read('in.jpg');
img.resize(256, Jimp.AUTO).quality(60).write('out.jpg');
img.getBase64(Jimp.MIME_PNG, cb);

// v1
import { Jimp } from 'jimp';
const img = await Jimp.read('in.jpg');
img.resize({ w: 256 });
await img.getBuffer('image/jpeg', { quality: 60 });
const uri = await img.getBase64('image/png');
```

## Best For / Avoid For
`browser-image-edit`, `serverless`, `zero-native-deps`, `prototyping`, `per-pixel-filters` — pick Jimp when portability beats raw speed.
Avoid for: high-throughput backends, very large images, animation authoring, or vector work.

## See Also
- `sharp.md` — the native, much faster server-side alternative
- `canvas-api.md` / `node-canvas.md` — pixel/drawing APIs when you need a 2D context
- `../use-case/image-processing.md`
