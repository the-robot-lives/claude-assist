# Mammoth.js — DOCX → Clean Semantic HTML (and Markdown)

Mammoth.js converts Microsoft Word **.docx** documents into clean, semantic HTML by mapping Word's *styles* (Heading 1, Quote, your custom paragraph/character styles) to meaningful HTML elements — not by trying to reproduce Word's exact visual formatting. The result is minimal markup (`<h1>`, `<p>`, `<ul>`, `<table>`, `<strong>`) suitable for a CMS, a static site, or further processing. It also emits **messages** (warnings) about anything it couldn't map, and can extract or inline embedded images. Conversion is one-way (DOCX → HTML/Markdown/plain text).

**Current Version**: mammoth@1.8.x (current major)  **License**: BSD-2-Clause  **Runtime**: Node.js and browsers (bundled build).

## Official Resources & Documentation
- GitHub (README is the reference): https://github.com/mwilliamson/mammoth.js
- npm: https://www.npmjs.com/package/mammoth
- Python port (same style-map concept): https://github.com/mwilliamson/python-mammoth

## Installation & Setup

### Package manager
```bash
npm install mammoth
```

### Import styles
```javascript
const mammoth = require('mammoth');        // CJS (Node)
import mammoth from 'mammoth';             // ESM
```

### Browser
```html
<script src="https://unpkg.com/mammoth/mammoth.browser.min.js"></script>
<script>
  document.getElementById('file').addEventListener('change', async (e) => {
    const arrayBuffer = await e.target.files[0].arrayBuffer();
    const { value: html, messages } = await mammoth.convertToHtml({ arrayBuffer });
  });
</script>
```

## Core API Reference

All entry points take an **input descriptor** and return a promise of `{ value, messages }`.

### Input descriptors
```javascript
mammoth.convertToHtml({ path: 'document.docx' });     // Node file path
mammoth.convertToHtml({ buffer: nodeBuffer });         // Node Buffer
mammoth.convertToHtml({ arrayBuffer });                // browser
```

### Conversion functions
```javascript
const html = await mammoth.convertToHtml({ path });          // → HTML string in .value
const md   = await mammoth.convertToMarkdown({ path });      // → Markdown
const text = await mammoth.extractRawText({ path });         // → plain text (no structure)
```

### Result object
```javascript
const result = await mammoth.convertToHtml({ path: 'doc.docx' });
result.value;      // the HTML/Markdown/text string
result.messages;   // [{ type: 'warning'|'error', message: '...' }]
```

## Style Mapping (the heart of Mammoth)

Word styles are matched by **name** and rewritten to HTML. `:fresh` starts a new element rather than nesting; without it, consecutive same-style paragraphs merge.

```javascript
const options = {
  styleMap: [
    "p[style-name='Heading 1'] => h1:fresh",
    "p[style-name='Heading 2'] => h2:fresh",
    "p[style-name='Intro'] => p.intro:fresh",         // custom class
    "p[style-name='Quote'] => blockquote:fresh",
    "r[style-name='Code'] => code",                    // r = run (character style)
    "p[style-name='Caption'] => p.caption:fresh",
    "b => strong",                                     // remap bold to <strong>
    "i => em",
    "u => span.underline",
    "comment-reference => sup",
  ],
};
const { value, messages } = await mammoth.convertToHtml({ path: 'doc.docx' }, options);
```
Selector syntax: `p[style-name='X']` (paragraph style), `r[style-name='X']` (run/character style), bare `b`/`i`/`u`/`strike` for direct formatting. Right-hand side is `element.class#id`; append `:fresh` to force element boundaries.

### Extending vs replacing the default map
```javascript
styleMap: [ /* your rules */ ],
includeDefaultStyleMap: true,   // default: your rules take precedence, defaults fill gaps
includeEmbeddedStyleMap: true,  // honour a style map embedded in the docx itself
```

## Images

By default images are inlined as base64 data URIs. Override with an image handler:
```javascript
const options = {
  convertImage: mammoth.images.imgElement(async (image) => {
    const buffer = await image.read('base64');
    return { src: `data:${image.contentType};base64,${buffer}` };
  }),
};
// Extract to disk instead of inlining:
let i = 0;
const extract = mammoth.images.imgElement(async (image) => {
  const buf = await image.read();               // Node Buffer
  const name = `img-${i++}.png`;
  await fs.promises.writeFile(`out/${name}`, buf);
  return { src: `images/${name}`, alt: image.altText || '' };
});
mammoth.convertToHtml({ path }, { convertImage: extract });
```

## How-To (worked recipes)

### How to map custom Word styles and add CSS classes (the "styling" recipe)
```javascript
const options = {
  styleMap: [
    "p[style-name='Title'] => h1.doc-title:fresh",
    "p[style-name='Subtitle'] => p.subtitle:fresh",
    "p[style-name='Callout'] => aside.callout:fresh",
    "r[style-name='Highlight'] => mark",
  ],
};
const { value } = await mammoth.convertToHtml({ path: 'brief.docx' }, options);
// Then style .doc-title, .subtitle, .callout, mark in your own CSS.
```
Mammoth deliberately drops Word's inline colours/fonts; you reintroduce presentation via CSS classes you map here.

### How to surface conversion warnings
```javascript
const { value, messages } = await mammoth.convertToHtml({ path: 'doc.docx' });
messages.filter(m => m.type === 'warning')
        .forEach(m => console.warn('Unmapped:', m.message));
// e.g. "Unrecognised paragraph style: 'Body Text 2' (Style ID: BodyText2)"
```
Warnings tell you exactly which styles to add to your `styleMap`.

### How to convert to Markdown for a static site
```javascript
const { value: markdown } = await mammoth.convertToMarkdown({ path: 'article.docx' });
await fs.promises.writeFile('article.md', markdown);
```

### How to transform a document element beyond style mapping
```javascript
const options = {
  transformDocument: mammoth.transforms.paragraph(p =>
    p.styleName === 'Heading 1' ? { ...p, alignment: 'center' } : p
  ),
};
```

## Do's and Don'ts

### ✅ Do
- Define a `styleMap` matched to the document's actual Word style names — that's how you get the HTML structure you want.
- Read `result.messages` and iterate: each "Unrecognised … style" warning is a rule to add.
- Use `:fresh` on block mappings so adjacent styled paragraphs don't merge into one element.
- Extract images to files for large documents instead of inlining base64 (keeps HTML small).
- Prefer `extractRawText` when you only need the text (search indexing, NLP).

### ❌ Don't
- Don't expect visual fidelity — Mammoth maps **meaning**, not Word's exact fonts/colours/spacing. That's by design.
- Don't feed it `.doc` (legacy binary), RTF, or PDF — **DOCX only**. Convert first.
- Don't rely on it for charts, SmartArt, text boxes, equations, or complex nested tables — these map poorly or are dropped (check messages).
- Don't assume it round-trips — there is no HTML→DOCX path here.

## Advanced Features
- `transformDocument` / `mammoth.transforms.paragraph|run` — programmatically rewrite the parsed tree before HTML generation.
- Embedded style maps: put a style map inside the docx so authors control mapping without code.
- `ignoreEmptyParagraphs: false` to preserve intentional blank paragraphs.
- `idPrefix` to namespace generated bookmark/footnote ids when embedding multiple documents in one page.

### How to handle a full ingestion pipeline (convert → sanitize → store)
```javascript
const { value: rawHtml, messages } = await mammoth.convertToHtml(
  { path: 'submission.docx' },
  { styleMap: myStyleMap, convertImage: extractImagesToDisk }
);
const clean = sanitizeHtml(rawHtml, {            // e.g. sanitize-html
  allowedTags: ['h1','h2','h3','p','ul','ol','li','strong','em','a','img','blockquote','table','thead','tbody','tr','th','td','figure','figcaption','aside','mark'],
  allowedAttributes: { a: ['href'], img: ['src','alt'], '*': ['class'] },
});
await cms.save({ html: clean, warnings: messages });
```
Always sanitize Mammoth output before rendering user-supplied documents — the HTML is clean structurally but still user content.

## Style-Map Selector Cheatsheet
```
p[style-name='Name']   paragraph with a named paragraph style
r[style-name='Name']   run (text span) with a named character style
p:unordered-list(1)    list paragraphs at nesting level 1  → ul > li
p:ordered-list(1)      ordered list level 1                → ol > li
b / i / u / strike      direct character formatting
comment-reference       Word comment markers
=> h2:fresh            map to <h2>, starting a NEW element
=> p.lead              map to <p class="lead">
=> !                    (empty target) drop the element entirely
```

## Integration Notes
- **Static-site generators**: `convertToMarkdown` feeds Markdown-based pipelines (Hugo, Jekyll, MkDocs) directly.
- **Browser upload**: use `mammoth.browser.min.js` and pass `{ arrayBuffer }` from a `FileReader`/`file.arrayBuffer()`.
- **Server queue**: DOCX→HTML is CPU-light but I/O-bound on images; extract images to object storage and rewrite `src` in the handler.
- **Python parity**: the `python-mammoth` port uses the same style-map strings, so a mapping designed once works in either runtime.

## Common Pitfalls & Troubleshooting
- *Headings come out as `<p>`* → the document uses a custom style name (e.g. "Heading1" vs "Heading 1"); map the exact name from the warning message.
- *Everything is one giant paragraph* → missing `:fresh`; add it to block-level rules.
- *Images missing* → default inlining hit a size/handler issue; supply a `convertImage` handler.
- *`.doc` fails* → not supported; only Office Open XML `.docx`.
- *Tables look flat* → Mammoth emits basic `<table>`; complex merged/nested tables lose structure.

## Best For / Avoid For
`docx-to-html`, `docx-to-markdown`, `content-migration`, `cms-import`, `word-ingestion`, `text-extraction` — ideal for pulling authored Word content into the web as clean markup.
Avoid for: preserving Word's exact look, converting legacy `.doc`/RTF/PDF, or generating DOCX.

## See Also
- `sheetjs.md` — the spreadsheet counterpart for documents-as-data ingestion
- `html.md` — the output target; style the mapped classes there
- `pdfkit.md` / `jspdf.md` — re-render converted content into PDF
- `../use-case/document-generation.md`, `../use-case/data-processing.md`
