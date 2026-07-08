# svg2pdf.js — Vector-Preserving SVG → PDF

svg2pdf.js renders an in-DOM **SVG element** directly into a jsPDF document as true vector graphics — paths stay paths, text stays selectable text, and output scales without pixelation. It's the right tool for exporting charts, technical diagrams, and vector illustrations to print-ready PDFs from the browser. It extends jsPDF by adding a `doc.svg(element, options)` method; jsPDF is a required peer dependency and does the actual PDF writing.

**Current Version**: svg2pdf.js@2.2.x (current major)  **License**: MIT  **Runtime**: browser (needs a real SVG DOM node); Node requires an SVG DOM shim (e.g. jsdom/svgdom).

## Official Resources & Documentation
- GitHub: https://github.com/yWorks/svg2pdf.js
- npm: https://www.npmjs.com/package/svg2pdf.js
- jsPDF (peer dep): https://github.com/parallax/jsPDF

## Installation & Setup

### Package manager
```bash
npm install svg2pdf.js jspdf
```

### Import styles
```javascript
import { jsPDF } from 'jspdf';
import 'svg2pdf.js';                 // side-effect import: augments jsPDF with .svg()
// or use the standalone function:
import { svg2pdf } from 'svg2pdf.js';
```

### CDN
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/svg2pdf.js@2/dist/svg2pdf.umd.min.js"></script>
```

## Core API Reference

### The `doc.svg()` method (added by the side-effect import)
```javascript
const doc = new jsPDF({ unit: 'pt', format: 'a4' });
const svgElement = document.getElementById('chart');   // a live <svg> node
await doc.svg(svgElement, {
  x: 20,            // left offset in the doc's unit
  y: 20,            // top offset
  width: 500,       // target render width  (defaults to the SVG's own size)
  height: 320,      // target render height
});
doc.save('chart.pdf');
```
`doc.svg()` returns a **Promise** — always `await` it (or `.then`) before saving.

### Standalone form
```javascript
await svg2pdf(svgElement, doc, { x: 20, y: 20, width: 500, height: 320 });
```

### Options
```javascript
{
  x: 0, y: 0,                          // placement in the PDF
  width: undefined, height: undefined, // omit to use the SVG's intrinsic dimensions
  loadExternalStyleSheets: false,      // pull in <link>/<style> rules that affect the SVG
}
```
The renderer honours the SVG `viewBox`, `preserveAspectRatio`, presentation attributes, and CSS that resolves on the element.

## What It Renders
Vector fills/strokes, paths, basic shapes (`rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`), `<text>`/`<tspan>` (as selectable PDF text), linear/radial **gradients**, `transform` matrices, `clipPath`, groups (`<g>`), and `<image>` (rasterized). Fonts embed if registered with jsPDF.

## How-To (worked recipes)

### How to export a D3/Chart SVG to a vector PDF
```javascript
import { jsPDF } from 'jspdf';
import 'svg2pdf.js';

async function exportSvg(svgSelector) {
  const svg = document.querySelector(svgSelector);
  const bbox = svg.getBoundingClientRect();
  const doc = new jsPDF({ orientation: bbox.width > bbox.height ? 'l' : 'p', unit: 'pt',
    format: [bbox.width + 40, bbox.height + 40] });
  await doc.svg(svg, { x: 20, y: 20, width: bbox.width, height: bbox.height });
  doc.save('export.pdf');
}
```

### How to keep colour, gradients, and fonts faithful
```javascript
// 1) Register the font used by the SVG so text embeds (not rasterizes):
doc.addFileToVFS('Inter.ttf', interBase64);
doc.addFont('Inter.ttf', 'Inter', 'normal');
// 2) Ensure fills/strokes are resolvable presentation attrs or inline styles:
//    <rect fill="#2b6cb0" stroke="#1a365d" />   or  style="fill:#2b6cb0"
// 3) Pull external CSS if the SVG relies on a stylesheet:
await doc.svg(svg, { x: 20, y: 20, width: 480, height: 300, loadExternalStyleSheets: true });
```
Colours come straight from the SVG's `fill`/`stroke`; gradients map to PDF gradient shadings. If colours look wrong, they're likely set by an unresolved external class — inline them or enable `loadExternalStyleSheets`.

### How to place multiple diagrams across pages
```javascript
const doc = new jsPDF({ unit: 'pt', format: 'a4' });
for (let i = 0; i < svgs.length; i++) {
  if (i > 0) doc.addPage();
  await doc.svg(svgs[i], { x: 30, y: 30, width: 535 });
}
doc.save('diagrams.pdf');
```

### How to render server-side with a DOM shim
```javascript
import { JSDOM } from 'jsdom';
import { jsPDF } from 'jspdf';
import { svg2pdf } from 'svg2pdf.js';
const dom = new JSDOM(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 100">
  <rect width="200" height="100" fill="#4ecdc4"/></svg>`);
const svg = dom.window.document.querySelector('svg');
const doc = new jsPDF({ unit: 'pt', format: [200, 100] });
await svg2pdf(svg, doc, { x: 0, y: 0, width: 200, height: 100 });
```

## Do's and Don'ts

### ✅ Do
- Always `await doc.svg(...)` before `doc.save()` — it's asynchronous.
- Embed the SVG's font in jsPDF (`addFileToVFS`/`addFont`) so `<text>` stays selectable and correctly shaped.
- Inline critical `fill`/`stroke`/`style`, or enable `loadExternalStyleSheets`, so styling resolves at render time.
- Size the PDF `format` to the SVG's bounding box to avoid clipping or huge margins.

### ❌ Don't
- Don't expect perfect fidelity for advanced SVG **filters** (blur, drop-shadow), complex `mask`s, or `foreignObject` — these are partially or unsupported; rasterize those regions first.
- Don't pass a detached/never-rendered node whose CSS never resolved — computed styles may be empty.
- Don't forget the jsPDF peer dependency — svg2pdf.js writes *through* jsPDF, it isn't standalone.
- Don't use it to **view** PDFs — it only produces them.

### How to export a specific size at print DPI
```javascript
// PDF uses points (72pt = 1in). For a 6"×4" print box:
const doc = new jsPDF({ unit: 'pt', format: [6 * 72, 4 * 72] });
await doc.svg(svg, { x: 0, y: 0, width: 6 * 72, height: 4 * 72 });
doc.save('6x4.pdf');
```
Vector output is resolution-independent, so there's no "DPI" to set — you size in physical units and the printer rasterizes at its own resolution.

## Integration Notes

### Charting libraries
Most chart libraries render to SVG (D3, Chart.js in SVG mode is not typical — Chart.js is canvas; but ECharts, Highcharts, ApexCharts, and D3 emit SVG). Grab the root `<svg>` node and pass it to `doc.svg()`:
```javascript
// D3 / generic
const svg = document.querySelector('#chart svg');
// Highcharts: chart.container.querySelector('svg')
// ECharts (svg renderer): chartInstance.getDom().querySelector('svg')
await doc.svg(svg, { x: 20, y: 20, width: 500 });
```
For **canvas-based** charts (Chart.js default, plain `<canvas>`), svg2pdf does not apply — use `canvas.toDataURL()` + `jspdf.addImage()` instead (raster, not vector).

### React
```javascript
const ref = useRef(null);            // ref on the <svg> element
async function exportPdf() {
  const doc = new jsPDF({ unit: 'pt', format: 'a4' });
  await doc.svg(ref.current, { x: 20, y: 20, width: 500 });
  doc.save('chart.pdf');
}
```

## Advanced Notes
- Text is emitted as PDF text runs when a matching font is registered; otherwise it may fall back or rasterize.
- `clipPath` and nested `transform`s are supported; deeply nested transforms can accumulate rounding.
- For charts, exporting the SVG (this tool) beats screenshotting to canvas — you keep crisp, selectable, scalable output.
- The renderer walks the live element's **computed** styles, so anything CSS applies (theme classes, `:root` variables resolved to values) is captured at export time.
- Combine with jsPDF's own drawing/text API to add titles, headers, and page numbers around the exported SVG.

## Common Pitfalls & Troubleshooting
- *Blank or partial output* → you didn't `await`; or the SVG had zero intrinsic size and no `width`/`height` option.
- *Wrong/black colours* → styles set via external CSS class weren't loaded; inline them or set `loadExternalStyleSheets: true`.
- *Text is an image / wrong font* → font not registered in jsPDF; add it before calling `doc.svg`.
- *Filters/shadows missing* → unsupported SVG features; pre-rasterize those parts (see `sharp.md`/`node-canvas.md`).

## Best For / Avoid For
`svg-to-pdf`, `chart-export`, `diagram-export`, `vector-illustration`, `print-ready`, `selectable-text` — the go-to for turning existing SVG into a vector PDF.
Avoid for: heavy SVG-filter effects, `foreignObject` HTML, or when you don't already have an SVG (generate the PDF directly with `pdfkit`/`jspdf`).

## See Also
- `jspdf.md` — the required PDF backend; also the general browser PDF generator
- `svg_js.md` — build the SVG you then export
- `pdfkit.md` — server-side alternative (use `svg-to-pdfkit` for the SVG bridge)
- `../use-case/document-generation.md`
