# PDFKit

## What
PDFKit is a JavaScript PDF-generation library offering a programmatic API for building PDF documents, running in both Node.js and browsers. The LLM emits imperative document-construction code (text, images, vector graphics, pages) that streams out a finished PDF.

## How
- **LLM emits:** JS creating `const doc = new PDFDocument()`, piping it to a destination, and issuing content calls (`doc.fontSize(25).text('Sample PDF', 100, 100)`, `doc.image(...)`, `doc.addPage()`), finishing with `doc.end()`.
- **Render path:** `npm install pdfkit`. In Node, `doc.pipe(fs.createWriteStream('output.pdf'))`; in the browser, pipe through `blobStream()` and use `stream.toBlobURL('application/pdf')`. Supports font embedding/subsetting and JPEG/PNG images.
- **Typical final artifact:** PDF file (Node) or Blob/object URL (browser).

## Why
- **Reach for it when:** you need programmatic PDF generation with vector graphics and embedded fonts — reports with dynamic data, invoices, and documents — on the server *or* in the browser.
- **Limitations:** complex layouts need manual positioning, no HTML/CSS-to-PDF conversion, tables require custom code, and limited text-flow control.
- **Relative to siblings:** PDFKit vs. jsPDF — both generate PDFs, but PDFKit leans server-side/Node with richer font and vector support and a streaming model, while jsPDF is lighter and browser-first.

## Source
- Solution reference: `fim/solution/pdfkit.md`
