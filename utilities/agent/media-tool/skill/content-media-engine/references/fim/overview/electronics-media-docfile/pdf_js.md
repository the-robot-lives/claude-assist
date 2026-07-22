# PDF.js

## What
PDF.js is Mozilla's JavaScript library for rendering PDF documents in web browsers with no plugins. It is a browser-side *viewer/parser* (not a generator); the LLM emits the JS that loads a PDF and renders its pages onto a canvas, plus optional text/annotation layer config.

## How
- **LLM emits:** JS using `pdfjsLib.getDocument('document.pdf').promise` then `pdf.getPage(1)`, computing a `viewport = page.getViewport({scale})` and calling `page.render({canvasContext, viewport})` against a `<canvas>`.
- **Render path:** load via CDN (`pdf.min.js` + set `GlobalWorkerOptions.workerSrc` to the worker) or `npm install pdfjs-dist`. Pages rasterize to canvas; a text layer enables selection/search and an annotation layer enables forms.
- **Typical final artifact:** rendered PDF pages on-canvas in the browser, plus extracted text.

## Why
- **Reach for it when:** you need in-browser PDF viewing, text extraction/search, screen-reader accessibility, form filling, or print/document preview without native plugins.
- **Limitations:** large library (~3MB), performance issues on complex PDFs, limited editing, and memory-intensive on large documents.
- **Relative to siblings:** PDF.js *consumes* PDFs (view/extract), the mirror image of pdfkit/jsPDF which *produce* them — pair PDF.js on the display side with a generator on the authoring side.

## Source
- Solution reference: `fim/solution/pdf_js.md`
