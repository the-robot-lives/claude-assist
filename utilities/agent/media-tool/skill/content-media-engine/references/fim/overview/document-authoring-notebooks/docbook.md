# DocBook

## What
DocBook is an XML schema designed for technical documentation — books, articles, and manuals — providing semantic markup for code, cross-references, and equations. Originally from O'Reilly, now an OASIS standard used in enterprise documentation workflows.

## How
- The LLM emits DocBook XML: a `<book>`/`<chapter>`/`<section>` structure with `<para>`, `<emphasis>`, and `<programlisting>` elements under the DocBook namespace.
- Rendered via XSLT stylesheets: `xsltproc` with the DocBook XSL to produce HTML, or transform to XSL-FO and run `fop` for PDF. XInclude supports document composition.
- Final artifact: HTML, PDF, EPUB, or man pages from a single source.

## Why
- Reach for DocBook for large technical manuals needing multiple output formats, strict schema validation, and complex cross-referencing, especially in organizations with established XML workflows and long-term archival needs.
- Tradeoffs: verbose markup, complex schema with a real learning curve, XSLT pipeline configuration, and customizing output appearance requires XSLT expertise.
- Versus DITA it favors narrative book/manual structure over topic-typed modular reuse; versus AsciiDoc it is heavier XML for the same multi-output goal.

## Source
- Solution reference: `fim/solution/docbook.md`
