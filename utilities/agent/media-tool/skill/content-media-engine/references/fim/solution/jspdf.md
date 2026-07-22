# jsPDF — Client-Side PDF Generation (browser-first)

jsPDF builds PDF documents directly in the browser (and Node) with a compact, coordinate-based API. It shines for lightweight, client-side output — invoices, receipts, certificates, exported reports — without any server round-trip. Text, lines, shapes, images, and multi-page documents are all supported; rich tables come via the near-ubiquitous **jspdf-autotable** plugin, and HTML capture via `html()` (which uses html2canvas under the hood). Default units are millimeters with an A4 portrait page.

**Current Version**: jspdf@2.5.x (current major)  **License**: MIT  **Runtime**: all modern browsers; also works in Node with a canvas shim.

## Official Resources & Documentation
- Docs: https://raw.githack.com/MrRio/jsPDF/master/docs/
- Getting started / API: https://github.com/parallax/jsPDF
- AutoTable plugin: https://github.com/simonbengtsson/jsPDF-AutoTable
- npm: https://www.npmjs.com/package/jspdf

## Installation & Setup

### Package manager
```bash
npm install jspdf
npm install jspdf-autotable    # optional: tables
```

### CDN
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.8.2/jspdf.plugin.autotable.min.js"></script>
```

### Import styles
```javascript
import { jsPDF } from 'jspdf';              // ESM (named export)
const { jsPDF } = require('jspdf');         // CJS
const { jsPDF } = window.jspdf;             // UMD global
```

## Constructor Options
```javascript
const doc = new jsPDF({
  orientation: 'portrait',   // 'portrait' | 'landscape' (or 'p'/'l')
  unit: 'mm',                // 'pt' | 'mm' | 'cm' | 'in' | 'px'
  format: 'a4',              // 'a4','letter','legal', or [width, height] in the chosen unit
  compress: true,
  putOnlyUsedFonts: true,
});
```

## Core API Reference

### Text
```javascript
doc.setFont('helvetica', 'bold');      // helvetica | times | courier (+ custom)
doc.setFontSize(16);
doc.setTextColor('#222');              // hex, or (r,g,b), or grayscale int
doc.text('Hello world', 10, 20);       // x, y in current unit (y is the text baseline)
doc.text('Right aligned', 200, 20, { align: 'right' });
doc.text(['line one', 'line two'], 10, 40);              // array = multiple lines
const lines = doc.splitTextToSize('long paragraph ...', 180); // wrap to width
doc.text(lines, 10, 60);
doc.text('Rotated', 10, 80, { angle: 45 });
```

### Shapes & lines
```javascript
doc.setDrawColor('#333');              // stroke colour
doc.setFillColor(240, 240, 255);       // fill colour
doc.setLineWidth(0.5);
doc.line(10, 100, 200, 100);
doc.rect(10, 110, 60, 30);             // outline
doc.rect(80, 110, 60, 30, 'F');        // 'S' stroke | 'F' fill | 'FD'/'DF' both
doc.roundedRect(150, 110, 50, 30, 3, 3, 'FD');
doc.circle(40, 160, 15, 'S');
doc.ellipse(120, 160, 25, 15, 'F');
doc.triangle(160, 150, 200, 150, 180, 180, 'FD');
```

### Images
```javascript
// format: PNG | JPEG | WEBP (browser-dependent). data: base64/data-URI/HTMLImageElement/Canvas
doc.addImage(dataUrl, 'PNG', 10, 190, 100, 60);        // x, y, w, h
doc.addImage(imgEl, 'JPEG', 10, 190, 100, 60, 'alias', 'FAST', 0); // ...alias, compression, rotation
```

### Pages
```javascript
doc.addPage('a4', 'landscape');
doc.setPage(1);
const n = doc.getNumberOfPages();
const { width, height } = doc.internal.pageSize;        // useful for centering / footers
```

### Output / save
```javascript
doc.save('document.pdf');                       // triggers browser download
const blob = doc.output('blob');                // Blob for upload
const uri  = doc.output('datauristring');       // data: URI
const buf  = doc.output('arraybuffer');         // Node/binary
window.open(doc.output('bloburl'));             // preview in new tab
```

## Tables with AutoTable
```javascript
import autoTable from 'jspdf-autotable';
autoTable(doc, {
  head: [['SKU', 'Item', 'Qty', 'Price']],
  body: [['A-1', 'Widget', '3', '$12'], ['B-7', 'Gadget', '1', '$40']],
  startY: 40,
  theme: 'striped',                     // 'striped' | 'grid' | 'plain'
  headStyles: { fillColor: [43, 108, 176], textColor: 255 },
  columnStyles: { 3: { halign: 'right' } },
  didDrawPage: (d) => doc.text(`Page ${doc.getNumberOfPages()}`, 10, 290),
});
const endY = doc.lastAutoTable.finalY;   // continue below the table
```

## How-To (worked recipes)

### How to control colour, fill, and text styling
```javascript
doc.setFillColor(43, 108, 176);          // RGB 0–255
doc.rect(10, 10, 190, 14, 'F');
doc.setTextColor(255, 255, 255);
doc.setFont('helvetica', 'bold').setFontSize(14);
doc.text('Invoice #1042', 14, 20);
doc.setTextColor('#333');                // reset to dark for body
```
jsPDF has no gradient primitive; fake gradients by stacking many thin filled rects, or embed a pre-rendered gradient image.

### How to generate a multi-page report that flows past one page
```javascript
const doc = new jsPDF();
const lines = doc.splitTextToSize(longText, 180);
let y = 20;
lines.forEach(line => {
  if (y > 280) { doc.addPage(); y = 20; }      // manual pagination guard
  doc.text(line, 15, y);
  y += 7;
});
doc.save('report.pdf');
```

### How to capture an HTML element to PDF
```javascript
await doc.html(document.getElementById('invoice'), {
  x: 10, y: 10, width: 190, windowWidth: 900,   // scale DOM to page width
  callback: (d) => d.save('invoice.pdf'),
});
```
`html()` rasterizes via html2canvas — text becomes an image (not selectable) and complex CSS may drift. For selectable text and crisp vectors, lay the document out with the native API instead.

### How to add a footer with page numbers
```javascript
const total = doc.getNumberOfPages();
for (let i = 1; i <= total; i++) {
  doc.setPage(i);
  doc.setFontSize(9).setTextColor('#888');
  doc.text(`${i} / ${total}`, doc.internal.pageSize.width - 20, doc.internal.pageSize.height - 8);
}
```

## Do's and Don'ts

### ✅ Do
- Wrap long text with `splitTextToSize` and guard page breaks manually — jsPDF does **not** auto-flow text.
- Use **jspdf-autotable** for anything tabular; hand-rolling grids is error-prone.
- Embed custom fonts (`doc.addFileToVFS` + `doc.addFont`) for non-Latin scripts — built-ins are Latin (WinAnsi) only.
- Prefer the native drawing API over `html()` when you need selectable text or small file size.

### ❌ Don't
- Don't rely on `html()` for pixel-perfect complex layouts — html2canvas has CSS gaps (some flex/grid, filters, web fonts).
- Don't forget `y` in `text()` is the **baseline**, not the top — content can clip at the page top if `y` is tiny.
- Don't add unsupported image formats — stick to PNG/JPEG (WebP support is browser-dependent).
- Don't assume mm everywhere — if you set `unit: 'pt'`, every coordinate is in points.

## Styling Notes
- Colours accept hex strings, `(r,g,b)` 0–255, or a single grayscale int. Set stroke via `setDrawColor`, fill via `setFillColor`, text via `setTextColor`.
- Fonts: `setFont(family, style)` where style ∈ `normal|bold|italic|bolditalic`. Register custom TTFs through the VFS APIs.
- Line style: `setLineWidth`, `setLineDashPattern([2,2], 0)`, `setLineCap('round')`.

### How to embed a custom (non-Latin) font
```javascript
// font must be a base64 TTF string
doc.addFileToVFS('NotoSans.ttf', notoBase64);
doc.addFont('NotoSans.ttf', 'NotoSans', 'normal');
doc.setFont('NotoSans');
doc.text('日本語 · Ελληνικά · Кириллица', 15, 30);
```
Built-in fonts are WinAnsi (Latin-1) only; any other script needs an embedded font.

### How to add an SVG or a canvas chart
```javascript
// Vector (best): use the svg2pdf.js plugin — see svg2pdf.md
import 'svg2pdf.js';
await doc.svg(document.querySelector('#chart svg'), { x: 10, y: 40, width: 190 });

// Raster fallback (canvas / Chart.js):
const dataUrl = chartCanvas.toDataURL('image/png');
doc.addImage(dataUrl, 'PNG', 10, 40, 190, 100);
```

## Integration Notes
- **AutoTable** is the de-facto plugin for tables; it auto-paginates, styles headers, and exposes hooks (`didDrawCell`, `didDrawPage`) for headers/footers and watermarks.
- **svg2pdf.js** adds `doc.svg()` for vector chart/diagram export (see `svg2pdf.md`) — preferred over screenshotting for crisp, selectable output.
- **React/Vue**: generate on a user action, not during render; return a Blob for preview (`URL.createObjectURL(doc.output('blob'))`) rather than forcing a download.
- **Node**: works with a canvas shim; for heavy server PDF work prefer `pdfkit` (streaming, richer vector API).

## Common Pitfalls & Troubleshooting
- *Text clipped at top* → `y` is the baseline; start around `y = fontSize/2 + margin`.
- *Blurry text via `html()`* → it's rasterized; switch to native `text()` for vector text.
- *Custom font ignored* → you must `addFileToVFS(name, base64)` then `addFont(name, family, style)` before `setFont`.
- *Table plugin "autoTable is not a function"* → import the plugin (`import 'jspdf-autotable'`) or use `doc.autoTable(...)` after the UMD script loads.
- *Huge file from `html()`* → html2canvas embeds a full-page bitmap; native layout is far smaller.

## Best For / Avoid For
`client-side-pdf`, `invoices`, `receipts`, `certificates`, `data-tables` (with AutoTable), `browser-export` — jsPDF is the default when generation must happen in the browser with no backend.
Avoid for: high-fidelity HTML→PDF (use headless Chrome/Puppeteer), or heavy vector/graphic authoring (use `pdfkit` server-side).

## See Also
- `pdfkit.md` — richer, streaming, server-oriented PDF generation
- `svg2pdf.md` — render an existing SVG DOM into a jsPDF document (vector-preserving)
- `pdf_js.md` — the viewer counterpart for rendering PDFs back to screen
- `../use-case/document-generation.md`
