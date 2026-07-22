# Mammoth.js

## What
Mammoth.js is a JavaScript library that converts Word (DOCX) documents into clean, semantic HTML without proprietary markup. It runs in both Node.js and the browser; the LLM's role is to emit the conversion call and any style-map configuration, with the DOCX as input and HTML as output.

## How
- **LLM emits:** JS calling `mammoth.convertToHtml({path: "document.docx"})` (Node) or `{arrayBuffer}` (browser), optionally with an `options.styleMap` array (e.g. `"p[style-name='Heading 1'] => h1:fresh"`).
- **Render path:** `npm install mammoth` (or include `mammoth.browser.min.js`). The promise resolves to `result.value` (the HTML) and `result.messages` (warnings); the HTML is then dropped into a page or CMS.
- **Typical final artifact:** semantic HTML (headings, lists, tables preserved).

## Why
- **Reach for it when:** you need one-way DOCX→HTML for document-import workflows, Word content migration, or CMS integration, and want clean structural markup with customizable style mapping.
- **Limitations:** one-way conversion only (DOCX to HTML), limited support for complex Word features (charts, SmartArt), and no direct PDF output.
- **Relative to siblings:** Mammoth.js is the *ingestion* end of the document group — it reads Word files into HTML, complementary to the PDF *generators* (pdfkit/jsPDF) and the PDF *reader* (PDF.js) that handle the output side.

## Source
- Solution reference: `fim/solution/mammoth_js.md`
