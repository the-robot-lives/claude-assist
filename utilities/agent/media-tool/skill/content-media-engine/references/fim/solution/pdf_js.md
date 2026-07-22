# PDF.js — Render & Read PDFs in the Browser (Mozilla)

PDF.js is Mozilla's pure-JavaScript engine for **parsing and rendering** PDF documents to an HTML canvas — no native plugin, no server. It powers Firefox's built-in viewer. Beyond drawing pages, it exposes the text content (for search, copy, and accessibility), renders an optional selectable **text layer** over the canvas, draws the **annotation layer** (links, form fields), and runs its parser in a **Web Worker** to keep the main thread responsive. Use it to view, preview, thumbnail, extract text from, or search PDFs — not to author them.

**Current Version**: pdfjs-dist@4.x (current major, ESM-first)  **License**: Apache-2.0  **Runtime**: modern browsers; Node for text extraction (no canvas rendering without a canvas shim).

## Official Resources & Documentation
- Home & examples: https://mozilla.github.io/pdf.js/
- API examples: https://mozilla.github.io/pdf.js/examples/
- GitHub: https://github.com/mozilla/pdf.js
- npm: https://www.npmjs.com/package/pdfjs-dist

## Installation & Setup

### Package manager
```bash
npm install pdfjs-dist
```

### ESM + worker (v4)
```javascript
import * as pdfjsLib from 'pdfjs-dist';
// The worker must be wired up or parsing blocks the main thread.
import workerUrl from 'pdfjs-dist/build/pdf.worker.min.mjs?url'; // bundler resolves the URL
pdfjsLib.GlobalWorkerOptions.workerSrc = workerUrl;
```

### CDN
```html
<script type="module">
  import * as pdfjsLib from 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.0.379/pdf.min.mjs';
  pdfjsLib.GlobalWorkerOptions.workerSrc =
    'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.0.379/pdf.worker.min.mjs';
</script>
```

## Core API Reference

### Loading a document
```javascript
const task = pdfjsLib.getDocument({
  url: '/doc.pdf',              // OR data: Uint8Array, OR httpHeaders / withCredentials
  cMapUrl: '/cmaps/', cMapPacked: true,        // CJK / CMap support
  standardFontDataUrl: '/standard_fonts/',      // embed-less fonts
  password: undefined,
});
task.onPassword = (updatePassword, reason) => updatePassword(prompt('Password:'));
const pdf = await task.promise;                 // PDFDocumentProxy
console.log(pdf.numPages);
const meta = await pdf.getMetadata();           // { info, metadata }
```

### Rendering a page to canvas
```javascript
const page = await pdf.getPage(1);              // 1-indexed
const scale = 1.5;
const viewport = page.getViewport({ scale });   // apply rotation via { scale, rotation: 90 }
const canvas = document.getElementById('c');
const context = canvas.getContext('2d');
canvas.width = Math.floor(viewport.width);
canvas.height = Math.floor(viewport.height);
const renderTask = page.render({ canvasContext: context, viewport });
await renderTask.promise;
```
For crisp output on HiDPI displays, multiply canvas pixel dimensions by `window.devicePixelRatio` and scale the viewport with a transform.

### Extracting text
```javascript
const page = await pdf.getPage(1);
const textContent = await page.getTextContent();
const text = textContent.items.map(i => i.str).join(' ');
// each item: { str, dir, transform:[a,b,c,d,e,f], width, height, fontName }
```

### The text layer (selectable overlay)
```javascript
import { TextLayer } from 'pdfjs-dist';
const textLayerDiv = document.getElementById('text-layer');   // absolutely positioned over canvas
textLayerDiv.style.width = `${viewport.width}px`;
textLayerDiv.style.height = `${viewport.height}px`;
const textLayer = new TextLayer({ textContentSource: page.streamTextContent(), container: textLayerDiv, viewport });
await textLayer.render();
```

### The annotation layer (links & form fields)
```javascript
const annotations = await page.getAnnotations();   // link/widget/text annotation records
// The AnnotationLayer builder positions clickable links and interactive form widgets over the page.
```

## Supported Capabilities
`page-rendering`, `text-extraction`, `full-text-search`, `text-layer-selection`, `annotation/links`, `AcroForm-fields`, `thumbnails`, `print-preview`, `password-protected docs`, `CJK via CMaps`. Editing/writing is **not** a goal — PDF.js reads and renders.

## How-To (worked recipes)

### How to control render quality, scale, and colour/background
```javascript
const dpr = window.devicePixelRatio || 1;
const viewport = page.getViewport({ scale: 1.0 });
canvas.width = Math.floor(viewport.width * dpr);
canvas.height = Math.floor(viewport.height * dpr);
canvas.style.width = `${viewport.width}px`;
canvas.style.height = `${viewport.height}px`;
await page.render({
  canvasContext: context,
  viewport,
  transform: dpr !== 1 ? [dpr, 0, 0, dpr, 0, 0] : null,
  background: '#ffffff',                 // page backdrop; use 'transparent' to composite over a colour
}).promise;
```
PDFs are colour-managed by the source; PDF.js honours embedded colours. Control only the *page background* and output resolution here.

### How to render all pages (paged viewer)
```javascript
for (let n = 1; n <= pdf.numPages; n++) {
  const page = await pdf.getPage(n);
  const viewport = page.getViewport({ scale: 1.2 });
  const c = document.createElement('canvas');
  c.width = viewport.width; c.height = viewport.height;
  document.getElementById('viewer').appendChild(c);
  await page.render({ canvasContext: c.getContext('2d'), viewport }).promise;
}
```

### How to search text across a document
```javascript
async function findPages(pdf, query) {
  const hits = [];
  for (let n = 1; n <= pdf.numPages; n++) {
    const tc = await (await pdf.getPage(n)).getTextContent();
    const text = tc.items.map(i => i.str).join(' ').toLowerCase();
    if (text.includes(query.toLowerCase())) hits.push(n);
  }
  return hits;
}
```

### How to generate a thumbnail
```javascript
const page = await pdf.getPage(1);
const viewport = page.getViewport({ scale: 0.2 });
const c = document.createElement('canvas');
c.width = viewport.width; c.height = viewport.height;
await page.render({ canvasContext: c.getContext('2d'), viewport }).promise;
const thumbUrl = c.toDataURL('image/png');
```

## Do's and Don'ts

### ✅ Do
- Always set `GlobalWorkerOptions.workerSrc` — without the worker, parsing runs on the main thread and janks the UI.
- Match the worker version exactly to the `pdfjs-dist` API version, or rendering silently fails.
- Reuse the `PDFDocumentProxy`; call `pdf.destroy()` / `page.cleanup()` to free memory in long sessions.
- Scale by `devicePixelRatio` for sharp text on retina screens.
- Provide `cMapUrl` + `standardFontDataUrl` if you render CJK or documents without embedded fonts.

### ❌ Don't
- Don't try to **edit or create** PDFs with PDF.js — use `pdfkit`/`jspdf` for authoring.
- Don't render giant pages at huge scale — canvas has max-dimension limits (~16k px) and memory blows up.
- Don't skip `renderTask.promise` — starting a new render on the same canvas before the previous finishes throws; cancel with `renderTask.cancel()` first.
- Don't ship a mismatched worker file — a 4.x API with a 3.x worker breaks with cryptic errors.

## Advanced Features
- **Web Worker**: parsing/decoding runs off-main-thread by default via `pdf.worker.mjs`.
- **Streaming/range requests**: with a server that supports HTTP range, PDF.js fetches only needed byte ranges for large files.
- **Print**: render each page at print resolution and feed the browser print pipeline (the reference viewer implements this).
- **Structured/tagged text**: `getTextContent({ includeMarkedContent: true })` exposes structure for accessibility.

### How to extract text server-side (Node) for indexing
```javascript
import { getDocument } from 'pdfjs-dist/legacy/build/pdf.mjs'; // 'legacy' build for Node
const pdf = await getDocument({ data: new Uint8Array(fs.readFileSync('doc.pdf')) }).promise;
let full = '';
for (let n = 1; n <= pdf.numPages; n++) {
  const tc = await (await pdf.getPage(n)).getTextContent();
  full += tc.items.map(i => i.str).join(' ') + '\n';
}
await pdf.destroy();
```
Use the `legacy` build in Node; rendering to canvas requires a canvas polyfill, but text extraction does not.

### How to render into a scrollable multi-page viewer with the text layer
```javascript
for (let n = 1; n <= pdf.numPages; n++) {
  const page = await pdf.getPage(n);
  const viewport = page.getViewport({ scale: 1.25 });
  const wrap = document.createElement('div');
  wrap.style.position = 'relative';
  const canvas = document.createElement('canvas');
  canvas.width = viewport.width; canvas.height = viewport.height;
  const textLayer = document.createElement('div');
  textLayer.className = 'textLayer';          // needs pdf_viewer.css for correct positioning
  wrap.append(canvas, textLayer);
  viewerEl.append(wrap);
  await page.render({ canvasContext: canvas.getContext('2d'), viewport }).promise;
  // then build the TextLayer over `textLayer` at the same viewport
}
```

## Integration Notes
- **Prebuilt viewer**: `pdfjs-dist/web/pdf_viewer.mjs` + `pdf_viewer.css` provide a full `PDFViewer`/`PDFPageView` with scrolling, zoom, search, and the text/annotation layers wired up — use it instead of hand-rolling for a real reader UI.
- **Bundlers**: the worker is a separate file; Vite/webpack need it emitted as an asset (`?url` import or a copy plugin). Version must match the main module.
- **React**: render inside `useEffect`, keep the `renderTask` in a ref, and call `renderTask.cancel()` on cleanup/re-render to avoid "canvas already in use" errors.
- **CSP**: the worker is loaded from a URL; allow `worker-src`/`script-src` for its origin (or use a same-origin copy).

## Common Pitfalls & Troubleshooting
- *"Setting up fake worker" warning / slow parse* → `workerSrc` not set or wrong path.
- *API version does not match Worker version* → align `pdfjs-dist` and the worker file versions.
- *Blurry pages* → not accounting for `devicePixelRatio`; scale canvas pixels up.
- *CJK text missing/boxed* → provide packed CMaps (`cMapUrl`, `cMapPacked: true`).
- *Selection doesn't line up* → the text layer div must exactly overlay the canvas at the same viewport dimensions.

## Best For / Avoid For
`pdf-viewing`, `text-extraction`, `search`, `thumbnails`, `document-preview`, `print-preview`, `accessibility` — the standard choice for showing/reading PDFs in a page.
Avoid for: creating or editing PDFs (use `pdfkit`/`jspdf`), or server-side rasterization at scale (native tooling like `pdfium`/`mutool` is faster).

## See Also
- `pdfkit.md` / `jspdf.md` — generate the PDFs that PDF.js displays
- `canvas-api.md` — the 2D surface PDF.js renders onto
- `../use-case/document-generation.md`
