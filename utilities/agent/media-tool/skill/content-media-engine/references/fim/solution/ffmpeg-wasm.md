# FFmpeg.wasm — In-Browser Video/Audio Processing (WebAssembly)

FFmpeg.wasm is a WebAssembly port of FFmpeg that runs the full transcoding/filtering engine **entirely client-side** — no upload, no server. You drive it with the same CLI argument arrays you'd pass native `ffmpeg`, operating on an in-memory virtual file system. It handles transcoding, trimming, concatenation, frame extraction, format conversion, filters (`-vf`/`-af`), and audio work. The costs are a large one-time WASM download and 2–10× slower-than-native execution bounded by browser memory.

**Current Version**: @ffmpeg/ffmpeg@0.12.x with @ffmpeg/util (current major)  **License**: MIT (wrapper); FFmpeg core is LGPL/GPL depending on build  **Runtime**: browsers with WebAssembly; single-thread core anywhere, multi-thread core needs cross-origin isolation.

## Official Resources & Documentation
- Docs: https://ffmpegwasm.netlify.app/
- API (0.12): https://ffmpegwasm.netlify.app/docs/api/ffmpeg/classes/FFmpeg/
- GitHub: https://github.com/ffmpegwasm/ffmpeg.wasm
- npm: https://www.npmjs.com/package/@ffmpeg/ffmpeg
- FFmpeg CLI reference (arguments are identical): https://ffmpeg.org/ffmpeg.html

## Installation & Setup

### Package manager
```bash
npm install @ffmpeg/ffmpeg @ffmpeg/util
# core is fetched at runtime; pin with @ffmpeg/core (single) or @ffmpeg/core-mt (multi-thread)
```

### Load (single-thread)
```javascript
import { FFmpeg } from '@ffmpeg/ffmpeg';
import { fetchFile, toBlobURL } from '@ffmpeg/util';

const ffmpeg = new FFmpeg();
const baseURL = 'https://unpkg.com/@ffmpeg/core@0.12.10/dist/umd';
await ffmpeg.load({
  coreURL: await toBlobURL(`${baseURL}/ffmpeg-core.js`, 'text/javascript'),
  wasmURL: await toBlobURL(`${baseURL}/ffmpeg-core.wasm`, 'application/wasm'),
});
```
`toBlobURL` sidesteps cross-origin worker restrictions by fetching the core into a same-origin blob.

### Load (multi-thread — faster, needs isolation)
```javascript
const baseURL = 'https://unpkg.com/@ffmpeg/core-mt@0.12.10/dist/umd';
await ffmpeg.load({
  coreURL:   await toBlobURL(`${baseURL}/ffmpeg-core.js`,     'text/javascript'),
  wasmURL:   await toBlobURL(`${baseURL}/ffmpeg-core.wasm`,   'application/wasm'),
  workerURL: await toBlobURL(`${baseURL}/ffmpeg-core.worker.js`, 'text/javascript'),
});
```
The multi-thread core uses `SharedArrayBuffer`, which requires the page to be **cross-origin isolated**. Serve with:
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```
Verify at runtime with `crossOriginIsolated === true`; fall back to the single-thread core if false.

## Core API Reference

The `FFmpeg` instance is a thin bridge over a worker running the WASM core.

```javascript
await ffmpeg.load(options);                       // boot the core
await ffmpeg.writeFile(name, data);               // data: Uint8Array | string; put file in MEMFS
const bytes = await ffmpeg.readFile(name);        // Uint8Array (or 'utf8' string)
await ffmpeg.deleteFile(name);
await ffmpeg.createDir('/frames');
await ffmpeg.listDir('/');                         // [{ name, isDir }]
await ffmpeg.exec(args, timeout);                  // run ffmpeg with a CLI arg array
await ffmpeg.exec(args, -1, { signal });           // AbortSignal-cancellable
ffmpeg.terminate();                                // kill worker, free memory
ffmpeg.loaded;                                     // boolean
```

### Events
```javascript
ffmpeg.on('log', ({ type, message }) => console.log(message)); // FFmpeg stderr banner + progress text
ffmpeg.on('progress', ({ progress, time }) => {                // progress 0..1, time in microseconds
  bar.value = progress;
});
```

### The virtual file system (MEMFS)
Everything `exec` touches must exist in MEMFS. Write inputs before, read outputs after, delete to reclaim RAM. Paths are POSIX (`/input.mp4`, `frames/%04d.png`). Files live only for the session and count against browser memory.

## Supported Operations & Codecs

Argument arrays mirror the CLI exactly. Codec/format availability depends on the core build (the default core is compiled with x264, libvpx, libmp3lame, aac, opus, and common demuxers/muxers).

```javascript
// Transcode MP4 → H.264 with a preset
await ffmpeg.exec(['-i', 'in.mov', '-c:v', 'libx264', '-preset', 'fast', '-crf', '23', 'out.mp4']);

// Extract audio
await ffmpeg.exec(['-i', 'in.mp4', '-vn', '-c:a', 'libmp3lame', '-q:a', '2', 'out.mp3']);

// Trim (fast, stream copy — no re-encode)
await ffmpeg.exec(['-ss', '00:00:05', '-i', 'in.mp4', '-t', '10', '-c', 'copy', 'clip.mp4']);

// Scale + fps via -vf (video filtergraph)
await ffmpeg.exec(['-i', 'in.mp4', '-vf', 'fps=10,scale=320:-1:flags=lanczos', 'out.gif']);

// Extract frames to PNG sequence
await ffmpeg.createDir('frames');
await ffmpeg.exec(['-i', 'in.mp4', '-vf', 'fps=1', 'frames/%04d.png']);

// Overlay a watermark
await ffmpeg.exec(['-i', 'in.mp4', '-i', 'logo.png',
  '-filter_complex', 'overlay=W-w-10:H-h-10', '-c:a', 'copy', 'wm.mp4']);
```

## How-To (worked recipes)

### How to convert a user-selected file and download the result
```javascript
async function convertToWebm(file) {
  await ffmpeg.writeFile('input', await fetchFile(file)); // fetchFile accepts File/Blob/URL/Uint8Array
  await ffmpeg.exec(['-i', 'input', '-c:v', 'libvpx-vp9', '-b:v', '1M', '-c:a', 'libopus', 'out.webm']);
  const data = await ffmpeg.readFile('out.webm');
  const url = URL.createObjectURL(new Blob([data.buffer], { type: 'video/webm' }));
  Object.assign(document.createElement('a'), { href: url, download: 'out.webm' }).click();
}
```

### How to control colour, format, and quality
```javascript
// CRF governs quality (lower = better, 18–28 typical for x264); -pix_fmt sets colour format
await ffmpeg.exec([
  '-i', 'in.mp4',
  '-vf', 'eq=saturation=1.1:contrast=1.05',   // colour grade
  '-c:v', 'libx264', '-crf', '20', '-preset', 'medium',
  '-pix_fmt', 'yuv420p',                        // widest player compatibility
  'graded.mp4'
]);
```
For GIF, pass through a palette for far better colour: generate `palettegen`, then `paletteuse`.

### How to make a high-quality GIF (two-pass palette)
```javascript
await ffmpeg.exec(['-i', 'in.mp4', '-vf', 'fps=12,scale=480:-1:flags=lanczos,palettegen', 'pal.png']);
await ffmpeg.exec(['-i', 'in.mp4', '-i', 'pal.png',
  '-filter_complex', 'fps=12,scale=480:-1:flags=lanczos[x];[x][1:v]paletteuse', 'out.gif']);
```

### How to show progress and allow cancellation
```javascript
const controller = new AbortController();
ffmpeg.on('progress', ({ progress }) => (bar.value = progress));
cancelBtn.onclick = () => controller.abort();
await ffmpeg.exec(['-i', 'in.mp4', '-c:v', 'libx264', 'out.mp4'], -1, { signal: controller.signal });
```

## Do's and Don'ts

### ✅ Do
- Detect `crossOriginIsolated` and load the **-mt** core only when true; otherwise use single-thread.
- Use `-c copy` for pure trims/remuxes — orders of magnitude faster than re-encoding.
- `deleteFile()` intermediate artifacts and call `terminate()` when done to free memory.
- Serve core `.wasm`/`.js` from your own origin (or via `toBlobURL`) to avoid worker CORS failures.
- Add `-pix_fmt yuv420p` to H.264 output so Safari/QuickTime can play it.

### ❌ Don't
- Don't process multi-GB files in the browser — MEMFS holds inputs, outputs, and working data in RAM; expect failures well before native limits.
- Don't assume multi-threading works everywhere — without COOP/COEP it silently can't allocate `SharedArrayBuffer`.
- Don't reuse the same MEMFS filename across runs without deleting — stale bytes cause confusing output.
- Don't block the main thread waiting; `exec` is async and long — drive UI from the `progress` event.
- Don't expect exotic codecs (HEVC encode, some pro formats) in the default core; they may be absent for licensing/size reasons.

### How to concatenate clips
```javascript
// Same codec/params → fast concat demuxer (no re-encode)
await ffmpeg.writeFile('a.mp4', await fetchFile(clipA));
await ffmpeg.writeFile('b.mp4', await fetchFile(clipB));
await ffmpeg.writeFile('list.txt', "file 'a.mp4'\nfile 'b.mp4'\n");
await ffmpeg.exec(['-f', 'concat', '-safe', '0', '-i', 'list.txt', '-c', 'copy', 'joined.mp4']);
```

### How to extract a thumbnail at a timestamp
```javascript
await ffmpeg.exec(['-ss', '00:00:03', '-i', 'in.mp4', '-frames:v', '1', '-q:v', '2', 'thumb.jpg']);
```

## Filter Reference (common `-vf` / `-af`)
```
scale=W:H            resize (use -1 to preserve aspect, flags=lanczos for quality)
crop=W:H:X:Y         crop rectangle
fps=N                force frame rate
transpose=1          rotate 90° (0..3 for other directions)
eq=brightness=..:contrast=..:saturation=..   colour grade
overlay=X:Y          composite (in -filter_complex with 2 inputs)
drawtext=text='..':x=..:y=..:fontsize=..     burn-in text (needs font in MEMFS)
volume=0.5           (-af) gain
atempo=1.5           (-af) speed up audio 0.5–2.0
```

## Integration Notes
- **Vite/webpack**: `@ffmpeg/core*` files are large assets; either host them and pass explicit `coreURL`/`wasmURL`, or use `toBlobURL` against a CDN. Don't bundle the WASM into JS.
- **React**: keep one `FFmpeg` instance in a ref, `load()` once on mount, and gate UI on a `loaded` flag; `terminate()` on unmount.
- **Next.js/SSR**: FFmpeg.wasm is browser-only — import it dynamically inside a client component (`'use client'`), never during SSR.
- **Web Worker**: run `exec` inside a worker for heavy jobs so the main thread stays responsive (the core already spawns its own worker, but wrapping keeps `writeFile`/`readFile` off the UI thread too).

## Performance & Limits
- **Download**: core WASM is tens of MB; cache aggressively (Service Worker / `toBlobURL` + HTTP cache).
- **Speed**: ~0.1–0.5× native single-thread; multi-thread narrows the gap on multi-core machines.
- **Memory**: bounded by the browser tab (often ~2–4 GB with `SharedArrayBuffer`); guard input size.
- **Threading**: single-thread core runs anywhere; `-threads` in args is ignored without the -mt core.

## Common Pitfalls & Troubleshooting
- *`SharedArrayBuffer is not defined`* → page isn't cross-origin isolated; add COOP/COEP headers or use single-thread core.
- *Worker/CORS errors loading core* → fetch core via `toBlobURL` or host it same-origin.
- *Output plays audio only / black video in Safari* → add `-pix_fmt yuv420p`.
- *"Conversion failed" with no output* → read the `log` events; usually an unsupported codec in the current core build or a missing MEMFS input.
- *Out-of-memory crash* → file too large; trim with `-c copy` first, lower resolution, or process in chunks.

## Best For / Avoid For
`client-side-video`, `privacy-first`, `trim`, `transcode`, `frame-extraction`, `gif-from-video`, `offline-pwa` — ideal when uploads are undesirable and files are modest.
Avoid for: large/long videos, batch server encoding (run native FFmpeg), or latency-critical real-time streaming.

## See Also
- `sharp.md` / `jimp.md` — still-image processing counterparts
- `canvas-api.md` — capture/draw frames to feed or receive from FFmpeg.wasm
- `../use-case/video-processing.md`, `../use-case/audio-processing.md`
