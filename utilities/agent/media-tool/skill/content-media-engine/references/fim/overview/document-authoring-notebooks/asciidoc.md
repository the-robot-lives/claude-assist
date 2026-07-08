# AsciiDoc

## What
AsciiDoc is a text document format for technical documentation, articles, and books, offering semantic markup with rich features (tables, footnotes, bibliographies, indexes, admonitions). It is consumed by the Asciidoctor processor and produces multiple output formats.

## How
- The LLM emits AsciiDoc text (`.adoc`): `=` document/section titles, `[source,python]` code blocks, `|===` tables, admonitions like `NOTE:`, and `image::`/link macros.
- Rendered by the Asciidoctor processor: `gem install asciidoctor` then `asciidoctor document.adoc` for HTML, or `asciidoctor-pdf document.adoc` for PDF; Asciidoctor.js is available via npm. Pandoc can also convert it.
- Final artifact: HTML, PDF, DocBook, EPUB, or man pages.

## Why
- Reach for AsciiDoc over Markdown when you need rich structured features — complex tables, cross-references, include directives for modular docs, and book-length authoring with multiple output targets.
- Tradeoffs: smaller community than Markdown, steeper syntax, requires the Asciidoctor processor, and fewer editors offer native preview.
- Versus Markdown it trades simplicity for power; versus DocBook it gives similar multi-output publishing with far lighter, more author-friendly syntax.

## Source
- Solution reference: `fim/solution/asciidoc.md`
