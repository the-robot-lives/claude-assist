# Jimp

## What
Jimp (JavaScript Image Manipulation Program) is a pure-JavaScript image-processing library with zero native dependencies. It runs in both Node.js and the browser, and the LLM emits a chainable, promise-based sequence of image operations that produces a transformed raster image.

## How
- **LLM emits:** JS using `Jimp.read(...)` followed by chained methods (e.g. `.resize(256,256).quality(60).greyscale().blur(5).write('output.jpg')`).
- **Render path:** `npm install jimp` (or include `jimp.js` via CDN in the browser). Read a source, chain transforms, and either `.write()` to disk (Node) or `image.getBase64(Jimp.MIME_PNG, cb)` to produce a data URL for an `<img>` (browser).
- **Typical final artifact:** PNG/JPEG/BMP/TIFF/GIF file or base64 data URL.

## Why
- **Reach for it when:** you need simple resize/crop/rotate/filter edits with no build hassle, cross-platform portability, or execution in serverless/browser environments where native bindings aren't an option.
- **Limitations:** slower than native libraries on large images, high memory use, narrower format support, and no GPU acceleration.
- **Relative to siblings:** Jimp vs. Sharp is the classic portability-vs-speed tradeoff — Jimp is pure-JS and runs anywhere (browser, serverless) but is slower, while Sharp is a native libvips binding that is far faster but Node-only.

## Source
- Solution reference: `fim/solution/jimp.md`
