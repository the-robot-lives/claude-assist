# Pandoc

## What
Pandoc is a universal document converter supporting 40+ formats (Markdown, HTML, LaTeX, DOCX, EPUB, PDF, RST, wiki formats). It is a command-line pipeline, not a markup language of its own, with academic features like citations and cross-references.

## How
- The LLM typically emits Markdown (or another source format) plus the pandoc command line to convert it.
- Run the `pandoc` CLI: e.g. `pandoc input.md -o output.pdf` (PDF needs LaTeX), `pandoc input.md -s -o output.html` for standalone HTML, `pandoc input.md -o output.docx` for Word, or `pandoc chapter*.md -o book.pdf`. Advanced use adds `--citeproc --bibliography`, custom `--template`, and `--lua-filter` transforms. Installs via `apt`/`brew`/`choco`.
- Final artifact: whichever target format is requested (PDF, HTML, DOCX, EPUB, etc.).

## Why
- Reach for Pandoc for document conversion, format migration, academic writing with bibliographies, and batch publishing of entire documentation sets from a single source.
- Tradeoffs: large install (~200MB, plus 1-3GB LaTeX for PDF), complex layouts may need manual adjustment, and it offers limited control over visual design versus dedicated typesetting tools.
- It is the conversion engine underneath Quarto and a common back-end for AsciiDoc/Markdown pipelines; reach for it when the goal is transforming between formats rather than authoring a site.

## Source
- Solution reference: `fim/solution/pandoc.md`
- Nested use-case detail: `fim/solution/pandoc/use-case/document-processing.md`
