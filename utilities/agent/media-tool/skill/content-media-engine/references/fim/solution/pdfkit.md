# PDFKit — Programmatic PDF Generation (vector, text, images, forms)

PDFKit is a JavaScript library for **building** PDF documents from code in Node.js and the browser. You place content imperatively with a cursor-and-coordinate model: set fonts, write flowing or absolutely-positioned text, draw vector paths, embed JPEG/PNG images, add links, annotations, outlines, and AcroForm fields. It streams output, so large documents don't buffer entirely in memory. PDFKit does **not** render HTML/CSS — you compose the page yourself.

**Current Version**: pdfkit@0.15.x (current major)  **License**: MIT  **Runtime**: Node.js and browsers (via `blob-stream` / bundlers).

## Official Resources & Documentation
- Docs & guide: https://pdfkit.org/
- Interactive demo/browser build: https://pdfkit.org/demo/browser.html
- GitHub: https://github.com/foliojs/pdfkit
- npm: https://www.npmjs.com/package/pdfkit

## Installation & Setup

### Package manager
```bash
npm install pdfkit
npm install blob-stream    # browser: turn the doc stream into a Blob/URL
```

### Node.js
```javascript
const PDFDocument = require('pdfkit');
const fs = require('fs');
const doc = new PDFDocument({ size: 'A4', margins: { top: 50, bottom: 50, left: 60, right: 60 } });
doc.pipe(fs.createWriteStream('out.pdf'));
doc.fontSize(24).text('Hello PDFKit');
doc.end();                       // MUST call end() to flush
```

### Browser
```javascript
import PDFDocument from 'pdfkit';
import blobStream from 'blob-stream';
const doc = new PDFDocument();
const stream = doc.pipe(blobStream());
doc.text('In the browser').end();
stream.on('finish', () => window.open(stream.toBlobURL('application/pdf')));
```

## Document Options
```javascript
new PDFDocument({
  size: 'A4',                 // 'A4','LETTER','LEGAL','A3',... or [width,height] in PDF points (72/in)
  layout: 'portrait',         // 'portrait' | 'landscape'
  margin: 50,                 // uniform, or margins:{top,bottom,left,right}
  bufferPages: true,          // enable page-range post-processing (e.g. page numbers)
  autoFirstPage: true,
  info: { Title: 'Report', Author: 'System', Subject: 'Q3' },
  pdfVersion: '1.7',
  compress: true,
});
```

## Core API Reference

### Text
```javascript
doc.font('Helvetica-Bold').fontSize(18).fillColor('#111')
   .text('Section Title', { align: 'left' });

doc.font('Helvetica').fontSize(11).fillColor('black')
   .text('Flowing paragraph text that wraps within the page margins automatically.', {
     align: 'justify',      // left | center | right | justify
     lineGap: 4,
     indent: 20,
     columns: 2, columnGap: 18,
     width: 400,
     link: 'https://example.com',   // make the run a hyperlink
     underline: false,
     continued: false        // true = next text() call continues the same line/run
   });

doc.text('Absolute', 100, 200);       // x, y explicit position
doc.moveDown(1);                        // advance the text cursor by 1 line
const h = doc.heightOfString('measure me', { width: 300 }); // layout probe
```

### Fonts
```javascript
// Standard 14 (no embedding): Helvetica, Times-Roman, Courier, Symbol, ZapfDingbats (+ Bold/Oblique variants)
doc.font('Times-Roman');
// Embed a custom TTF/OTF (subsetted automatically)
doc.registerFont('Body', 'fonts/Inter-Regular.ttf');
doc.font('Body').fontSize(12).text('Custom typeface');
// TrueType Collection: pass the family name
doc.font('fonts/Fonts.ttc', 'PostScriptName');
```

### Vector graphics
```javascript
doc.moveTo(50, 50).lineTo(150, 50).lineTo(100, 120).closePath()
   .fill('#f06');                              // fill a path
doc.rect(200, 50, 120, 60).lineWidth(2).stroke('#333');
doc.roundedRect(200, 130, 120, 60, 8).fillAndStroke('#eef', '#88a');
doc.circle(120, 220, 40).fill('red');
doc.path('M 250 250 L 300 300 L 250 350 Z').stroke();   // raw SVG path data
doc.save().translate(400, 400).rotate(20).rect(0, 0, 40, 40).fill('#0a7').restore();
```

### Images
```javascript
doc.image('logo.png', 60, 60, { width: 120 });     // JPEG & PNG only
doc.image('photo.jpg', { fit: [250, 200], align: 'center', valign: 'center' });
doc.image(bufferOrBase64, 60, 300, { width: 200 });
```

### Pages & flow
```javascript
doc.addPage({ size: 'A4', layout: 'landscape' });
doc.on('pageAdded', () => doc.fontSize(9).text('Header', 60, 20)); // running header
```

### Links, annotations, outlines
```javascript
doc.text('Anchor', { destination: 'chapter1' });
doc.link(x, y, w, h, 'https://example.com');       // clickable rectangle
doc.note(x, y, w, h, 'Reviewer comment');          // text annotation
doc.highlight(x, y, w, h);
const top = doc.outline.addItem('Chapter 1');      // PDF bookmarks
top.addItem('1.1 Intro');
```

### AcroForm fields
```javascript
doc.initForm();
doc.formText('fullName', 60, 100, 200, 20, { borderColor: 'gray' });
doc.formCheckbox('agree', 60, 140, 15, 15);
doc.formCombo('country', 60, 170, 200, 20, { select: ['US', 'CA', 'MX'] });
```

## How-To (worked recipes)

### How to control colour, fills, gradients, and opacity
```javascript
doc.fillColor('#2b6cb0');                    // hex, named, or [r,g,b]/[c,m,y,k] arrays
doc.fillColor([255, 128, 0]);                // RGB 0–255
doc.strokeColor('cmyk', 0, 0.5, 1, 0);       // CMYK 0–1
doc.fillOpacity(0.4).rect(60, 60, 200, 80).fill('purple').fillOpacity(1);

const grad = doc.linearGradient(60, 0, 300, 0);
grad.stop(0, '#ff6b6b').stop(1, '#4ecdc4');
doc.rect(60, 160, 240, 60).fill(grad);

const radial = doc.radialGradient(150, 300, 0, 150, 300, 80);
radial.stop(0, 'white').stop(1, '#333');
doc.circle(150, 300, 80).fill(radial);
```

### How to draw a simple data table (PDFKit has no table primitive)
```javascript
const rows = [['SKU', 'Qty', 'Price'], ['A-1', '3', '$12'], ['B-7', '1', '$40']];
let y = 100; const cols = [60, 240, 340];
rows.forEach((row, r) => {
  doc.font(r === 0 ? 'Helvetica-Bold' : 'Helvetica').fontSize(11);
  row.forEach((cell, c) => doc.text(cell, cols[c], y, { width: 120 }));
  y += 22;
  doc.moveTo(60, y - 6).lineTo(420, y - 6).strokeColor('#ddd').stroke();
});
```

### How to number pages after all content is laid out
```javascript
const doc = new PDFDocument({ bufferPages: true });
// ... write content across pages ...
const range = doc.bufferedPageRange();          // { start, count }
for (let i = range.start; i < range.start + range.count; i++) {
  doc.switchToPage(i);
  doc.fontSize(9).text(`Page ${i + 1} of ${range.count}`, 60, doc.page.height - 40, { align: 'center' });
}
doc.end();
```

### How to embed a chart image and caption it
```javascript
doc.image(chartPngBuffer, { fit: [480, 300], align: 'center' });
doc.moveDown(0.5).font('Helvetica-Oblique').fontSize(9)
   .text('Figure 1. Quarterly revenue.', { align: 'center' });
```

## Do's and Don'ts

### ✅ Do
- Always `doc.end()` — nothing is flushed until you do.
- Use `bufferPages: true` when you need page numbers, totals, or headers that depend on final page count.
- Embed TTF/OTF for non-Latin scripts; the built-in Standard-14 fonts are Latin-only (WinAnsi).
- Probe layout with `heightOfString` / `widthOfString` before positioning to avoid overflow.
- Convert SVG/complex graphics to a path or a rasterized image first — PDFKit draws paths, not markup.

### ❌ Don't
- Don't feed it HTML/CSS — there is no HTML renderer. Use a headless-browser tool (Puppeteer) for that, or lay out manually.
- Don't `image()` a GIF/WebP/SVG — only JPEG and PNG are supported; rasterize others first (see `sharp.md`).
- Don't assume text auto-paginates infinitely mid-cell; flowing `text()` adds pages, but manual-position text can silently overflow.
- Don't forget CMYK vs RGB intent for print — mixing colour spaces can shift output on press.

## Advanced Features
- **Streaming**: pipe to HTTP responses (`doc.pipe(res)`) for zero-buffer server delivery.
- **Encryption/permissions**: `new PDFDocument({ userPassword, ownerPassword, permissions: { printing: 'highResolution' } })`.
- **Metadata & PDF/A**: set `info` and `pdfVersion`; tagging/accessibility support is partial.
- **SVG**: use the `svg-to-pdfkit` add-on to render SVG onto a PDFKit doc.

## Common Pitfalls & Troubleshooting
- *Blank/truncated file* → you never called `end()`, or read the stream before `finish`.
- *Custom characters render as boxes* → the current font lacks those glyphs; register a font that covers the script.
- *Image won't embed* → not JPEG/PNG; rasterize to PNG first.
- *Text overlaps* → mixing absolute `text(str, x, y)` with flow; track `doc.y` or use `moveDown`.

## Best For / Avoid For
`programmatic-pdf`, `invoices`, `reports`, `certificates`, `server-pdf`, `forms` — pick PDFKit when you generate PDFs from structured data with precise control.
Avoid for: converting existing HTML pages to PDF (use a headless browser), or heavy tabular layouts (consider `jspdf` + AutoTable, or an HTML→PDF route).

## See Also
- `jspdf.md` — browser-first PDF generator with an AutoTable plugin
- `svg2pdf.md` — render existing SVG DOM into a (jsPDF) PDF
- `pdf_js.md` — the complementary library for *viewing* PDFs
- `../use-case/document-generation.md`
