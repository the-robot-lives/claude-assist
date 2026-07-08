# jsPDF

## What
jsPDF is a client-side PDF-generation library for creating PDFs directly in the browser. Its primary consumer is browser JavaScript; the LLM emits imperative drawing/text calls that assemble a document and trigger a download.

## How
- **LLM emits:** JS creating `const doc = new jsPDF()` then adding content — `doc.text('Hello world!', 10, 10)`, `doc.setFontSize(16)`, `doc.addPage()`, `doc.addImage(imageData,'PNG',10,50,100,75)`, `doc.rect(...)`, `doc.circle(...)` — ending with `doc.save('document.pdf')`.
- **Render path:** `npm install jspdf` or CDN `jspdf.umd.min.js`. Build the document with the API; a plugin ecosystem (autotable, html2canvas) adds tables and HTML capture.
- **Typical final artifact:** a downloaded PDF file, generated entirely client-side.

## Why
- **Reach for it when:** you need lightweight, fully client-side PDF creation — simple reports, invoices, receipts, certificates — where no server is available or desired.
- **Limitations:** less layout control than server-side tools, manual positioning for complex layouts, font embedding grows file size, and no native HTML/CSS rendering (needs the html2canvas plugin).
- **Relative to siblings:** jsPDF is the browser-first, lightweight counterpart to PDFKit's richer server-side generation — and it is the required dependency that svg2pdf.js builds on to convert SVG into PDF.

## Source
- Solution reference: `fim/solution/jspdf.md`
