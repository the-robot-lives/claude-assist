# HTML

## What
HTML (HyperText Markup Language) is the semantic markup language for structuring web-based documentation and interactive content. HTML5 provides semantic elements (`article`, `section`, `nav`, `aside`), native multimedia embedding, and built-in accessibility features.

## How
- The LLM emits HTML5 markup: a `<!DOCTYPE html>` document with `<head>` metadata and a semantic `<body>` using `article`/`header`/`section`/`figure`/`aside`/`footer`, `<strong>` emphasis, and `<img>`/`<figcaption>`.
- Rendered directly by any web browser; sophisticated layouts require CSS, and interactivity integrates JavaScript.
- Final artifact: a rendered web page (documentation site, tutorial, reference portal, knowledge base).

## Why
- Reach for raw HTML when you want universal browser support, native multimedia (audio/video/canvas), direct JavaScript integration, and built-in ARIA/semantic accessibility — ideal for web docs, interactive tutorials, and API portals.
- Tradeoffs: not optimized for print, no native pagination, limited offline capability without service workers, and it needs CSS for advanced layout.
- It is the common render target that the other tools in this category (Markdown, SSGs, Sphinx, Pandoc) ultimately compile down to; author it directly when you need full control over the final markup.

## Source
- Solution reference: `fim/solution/html.md`
