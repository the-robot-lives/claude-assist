# FFmpeg.wasm

## What
FFmpeg.wasm is a WebAssembly port of FFmpeg that runs full video and audio processing entirely in the browser, with no server-side infrastructure. Its primary consumer is browser JavaScript (with a Node path available); the LLM emits FFmpeg command arguments plus the JS glue to load the WASM core and shuttle files in and out.

## How
- **LLM emits:** FFmpeg CLI-style argument arrays passed to `ffmpeg.exec([...])`, e.g. `['-i', 'input.mp4', '-vf', 'fps=10,scale=320:-1', 'output.gif']`, wrapped in the load/writeFile/exec/readFile lifecycle.
- **Render path:** `npm install @ffmpeg/ffmpeg @ffmpeg/core`; create `const ffmpeg = new FFmpeg()`, `await ffmpeg.load({...})`, `writeFile` the input, `exec` the command, then `readFile` the output and wrap it in a `Blob`/object URL. The `@ffmpeg/util` `fetchFile`/`toBlobURL` helpers move data across the WASM filesystem boundary.
- **Typical final artifact:** any FFmpeg-supported media output (mp4, webm, gif, mp3, wav, png frames, etc.) returned as a browser Blob.

## Why
- **Reach for it when:** you need client-side transcode/trim/compress/frame-extraction/thumbnailing with familiar FFmpeg syntax, especially for privacy-sensitive or offline-first apps where media must never leave the device.
- **Limitations:** ~30MB core WASM download, 2–10x slower than native FFmpeg, browser memory constraints, and single-threaded execution in most browsers.
- **Relative to siblings:** FFmpeg.wasm is the video/audio powerhouse of this media group — where Sharp/Jimp/node-canvas handle still images, FFmpeg.wasm owns time-based media, and it does so client-side rather than on a server.

## Source
- Solution reference: `fim/solution/ffmpeg-wasm.md`
- Nested use-case detail: `fim/solution/ffmpeg-wasm/use-case/media-processing.md`
