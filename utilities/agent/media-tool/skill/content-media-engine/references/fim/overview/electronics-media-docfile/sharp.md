# Sharp

## What
Sharp is a high-performance Node.js image-processing module built on the libvips C library, used for resizing, converting, and manipulating images at scale. It is server-side only (Node.js); the LLM emits a chained Sharp pipeline that outputs an optimized raster image.

## How
- **LLM emits:** JS using `sharp('input.jpg')` with chained operations (e.g. `.resize(300,200).toFormat('webp').toFile('output.webp')`, or `.resize({width:800}).jpeg({quality:80}).blur(2).toBuffer()`).
- **Render path:** `npm install sharp` (pre-built binaries on most platforms; libvips/`vips` may be needed on some). Build the pipeline and terminate with `.toFile(...)` or `.toBuffer()`; streaming and buffer I/O are supported for throughput.
- **Typical final artifact:** JPEG, PNG, WebP, AVIF, TIFF, GIF (SVG rasterized).

## Why
- **Reach for it when:** you need the fastest Node.js image processing for server-side pipelines, batch optimization, thumbnail services, or real-time transformation APIs with a low memory footprint.
- **Limitations:** Node.js only (no browser/client-side), platform-specific binary dependencies, and SVG support limited to rasterization.
- **Relative to siblings:** Sharp is the native-binding speed choice versus Jimp's pure-JS portability — pick Sharp for high-throughput server work, Jimp when you need to run in the browser or a binding-free serverless runtime.

## Source
- Solution reference: `fim/solution/sharp.md`
- Nested use-case detail: `fim/solution/sharp/use-case/media-processing.md`
