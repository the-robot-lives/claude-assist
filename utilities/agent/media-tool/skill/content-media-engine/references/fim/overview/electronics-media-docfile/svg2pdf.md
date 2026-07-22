# svg2pdf.js

## What
svg2pdf.js is a JavaScript library that converts SVG elements directly to PDF while preserving vector graphics and selectable text. It is browser-oriented and layered on top of jsPDF; the LLM emits the call that hands an SVG DOM element to a jsPDF document.

## How
- **LLM emits:** JS that imports jsPDF plus `svg2pdf.js`, then calls `doc.svg(svgElement, {x, y, width, height})` and resolves with `doc.save('output.pdf')`; options include `preserveAspectRatio` and `loadExternalStyleSheets`.
- **Render path:** `npm install svg2pdf.js jspdf`. Grab an SVG element from the DOM, call `doc.svg(...)` (which returns a promise), then save — the SVG is embedded as true vector content, no intermediate rasterization.
- **Typical final artifact:** PDF with scalable vector graphics and selectable text.

## Why
- **Reach for it when:** you need to export charts, technical diagrams, or vector illustrations to print-ready PDF while keeping them scalable and their text selectable — e.g. exporting a web visualization.
- **Limitations:** complex gradients/filters may not render perfectly, some SVG features have limited support, jsPDF is a required dependency, and very complex SVGs hit performance issues; browser-oriented (not server-compatible).
- **Relative to siblings:** svg2pdf.js is the SVG-specialized bridge that sits on jsPDF — use it when your source is already SVG and vector fidelity matters, versus drawing PDF content imperatively with jsPDF/PDFKit directly.

## Source
- Solution reference: `fim/solution/svg2pdf.md`
