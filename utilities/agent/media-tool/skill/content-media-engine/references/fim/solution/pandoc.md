# Pandoc — Universal document converter

Pandoc is the "swiss-army knife" of document conversion: it reads ~40 input formats and writes ~60 output formats through a common internal abstract syntax tree (AST). Convert Markdown ↔ HTML ↔ LaTeX ↔ DOCX ↔ EPUB ↔ RST ↔ DocBook, apply citations and cross-references, and reshape documents with Lua filters. It is the engine behind R Markdown, Quarto, and countless publishing pipelines.

**Current Version**: Pandoc 3.x (current major)  **License**: GPL-2.0+  **Runtime**: single Haskell binary `pandoc`; PDF output needs a TeX engine (or `wkhtmltopdf`/`weasyprint`/`typst`)

## Official Resources & Documentation
- **Website**: https://pandoc.org/
- **Full manual (MANUAL)**: https://pandoc.org/MANUAL.html
- **Installing**: https://pandoc.org/installing.html
- **Lua filters guide**: https://pandoc.org/lua-filters.html
- **Filters (AST) overview**: https://pandoc.org/filters.html
- **Templates**: https://pandoc.org/MANUAL.html#templates
- **GitHub**: https://github.com/jgm/pandoc

## Installation & Setup
```bash
apt-get install pandoc                 # Debian/Ubuntu (may lag; prefer GitHub release)
brew install pandoc                    # macOS
choco install pandoc                   # Windows

# For PDF output, add a TeX engine (see latex.md):
brew install --cask mactex             # or texlive / tinytex
# Or a lighter path:
pandoc in.md -o out.pdf --pdf-engine=typst   # Pandoc 3.x, no TeX needed
```

## Core Usage & Conversion Reference

### Basic invocation
```bash
pandoc input.md -o output.html         # format inferred from extensions
pandoc -f gfm -t docx input.md -o output.docx   # explicit from/to
pandoc -s input.md -o output.html      # -s = standalone (full doc, not fragment)
pandoc *.md -o book.pdf                # concatenate multiple inputs
pandoc input.md -o out.pdf --pdf-engine=xelatex
```
`-f/--from` = input format, `-t/--to` = output format, `-o` = output file, `-s/--standalone` wraps output in a full document template.

### Key input formats
`markdown` (Pandoc's extended dialect), `gfm`, `commonmark`, `commonmark_x`, `html`, `latex`, `rst`, `docx`, `odt`, `epub`, `docbook`, `mediawiki`, `org`, `textile`, `jupyter` (ipynb), `csv`, `bibtex`, `typst`.

### Key output formats
`html`/`html5`, `latex`, `pdf` (via engine), `docx`, `odt`, `epub2`/`epub3`, `rst`, `asciidoc`, `docbook5`, `man`, `revealjs`/`beamer`/`pptx` (slides), `gfm`, `commonmark`, `plain`, `json` (the AST), `typst`.

### Enabling / disabling Markdown extensions
```bash
# Turn extensions on (+) or off (-) after the format name:
pandoc -f markdown+hard_line_breaks-smart input.md -o out.html
pandoc -f markdown-yaml_metadata_block  input.md -o out.html
```
Extensions include `footnotes`, `pipe_tables`, `tex_math_dollars`, `raw_html`, `fenced_divs`, `bracketed_spans`, `implicit_figures`, `smart`.

### Metadata (YAML front matter or --metadata)
```yaml
---
title: "My Document"
author: "Author Name"
date: "2024-06-01"
lang: en-US
toc: true
number-sections: true
bibliography: refs.bib
---
```
```bash
pandoc --metadata title="Override" --toc input.md -o out.html
```

### Citations & bibliography
```bash
pandoc paper.md --citeproc --bibliography=refs.bib \
       --csl=chicago-author-date.csl -o paper.pdf
```
In the source: `[@smith2020]` or `@smith2020` for citations; `--citeproc` formats them and appends a reference list. `--csl` selects the citation style (thousands at the Zotero Style Repository).

### Table of contents, sections, numbering
```bash
pandoc --toc --toc-depth=3 --number-sections -s input.md -o out.html
```

### Cross-references (via filter)
```bash
pandoc input.md --filter pandoc-crossref --citeproc -o out.pdf
```
`pandoc-crossref` resolves `@fig:label`, `@tbl:label`, `@eq:label`, `@sec:label` into numbered references (Pandoc core numbers sections but not figures/tables).

## Templates & Styling

### Custom templates
```bash
pandoc --print-default-template=html5 > mytemplate.html   # start from default
pandoc input.md --template=mytemplate.html -o out.html
```
Templates are text files with `$variable$`, `$if(x)$...$endif$`, and `$for(y)$...$endfor$` placeholders populated from metadata.

### HTML styling
```bash
pandoc input.md -s --css=style.css -o out.html
pandoc input.md -s --embed-resources --standalone -o out.html   # inline CSS/images
```

### DOCX / PPTX styling (reference doc)
```bash
pandoc -o reference.docx --print-default-data-file reference.docx
# edit styles in reference.docx, then:
pandoc input.md --reference-doc=reference.docx -o output.docx
```
Word/PowerPoint styling is controlled by a **reference document** whose named styles Pandoc maps onto.

## How-To (worked recipes)

### How to add styling / theming to output
The "add styling" recipe differs per target — CSS for HTML, a reference doc for Word, a template + LaTeX packages for PDF:
```bash
# HTML: custom stylesheet + variables
pandoc report.md -s --css=theme.css \
  -V maxwidth=52em -V mainfont="Georgia" -o report.html

# PDF (LaTeX): pass geometry/color via template variables
pandoc report.md -o report.pdf \
  -V geometry:margin=1in -V linkcolor=blue -V documentclass=report

# DOCX: brand styles live in the reference doc
pandoc report.md --reference-doc=brand-template.docx -o report.docx
```
```css
/* theme.css for the HTML build */
body { font-family: Georgia, serif; max-width: 52em; margin: 2rem auto; }
h1, h2 { color: #1e6fba; }
code { background: #f5f7fa; padding: 0 .3em; }
```
`-V key=value` sets template variables; each writer exposes its own (e.g. `mainfont`, `geometry`, `linkcolor`, `theme` for revealjs).

### How to write a Lua filter (transform the AST)
```lua
-- emphasize-todo.lua : turn the word TODO into bold red
function Str(el)
  if el.text == "TODO" then
    return pandoc.Strong{ pandoc.Str("TODO") }
  end
end
```
```bash
pandoc input.md --lua-filter=emphasize-todo.lua -o out.html
```
Lua filters walk the AST and rewrite element types (`Str`, `Header`, `CodeBlock`, `Image`, `Link`, …) — the most powerful Pandoc customization, no recompilation needed.

### How to generate slides
```bash
pandoc slides.md -t revealjs -s -o slides.html -V theme=moon
pandoc slides.md -t beamer -o slides.pdf -V theme=Madrid
pandoc slides.md -o slides.pptx
```
Level-1/2 headings become slide boundaries (`--slide-level` controls which).

### How to build an EPUB book
```bash
pandoc metadata.yaml chapters/*.md \
  --toc --epub-cover-image=cover.png \
  --css=epub.css -o book.epub
```

## Do's and Don'ts

### ✅ Do
- Use **`-s/--standalone`** whenever you want a complete, self-contained document (Pandoc defaults to a fragment).
- Prefer **Lua filters** over shell post-processing for structural transforms — they operate on the typed AST.
- Set the **input dialect explicitly** (`-f gfm` vs `-f markdown`) — Pandoc Markdown ≠ GFM ≠ CommonMark.
- Use **`--citeproc`** (built in since 2.11) rather than the old external `pandoc-citeproc`.
- Use **`--pdf-engine=typst`** (Pandoc 3.x) to make PDFs without a multi-GB TeX install.

### ❌ Don't
- Don't expect **pixel-perfect layout** — Pandoc converts structure/semantics, not visual design; fine layout needs the target's native tooling.
- Don't forget a **PDF engine** — `-o out.pdf` fails with "pdflatex not found" until you install TeX (or use `--pdf-engine=...`).
- Don't rely on `raw_html`/`raw_tex` surviving conversion — raw blocks only pass through to matching writers.
- Don't mix up `--filter` (any executable, JSON protocol) with `--lua-filter` (built-in Lua) — different invocation.
- Don't assume every extension is available in every dialect — check `pandoc --list-extensions=gfm`.

## Advanced Features
- **AST as JSON**: `pandoc -t json` / `-f json` lets external programs (in any language) transform documents; `--filter` scripts use this protocol.
- **`--defaults`**: put all options in a YAML defaults file (`pandoc --defaults=build.yaml`) for reproducible builds.
- **Variables & metadata files**: `--metadata-file=meta.yaml` separates content from config.
- **`--include-in-header`/`--include-before-body`/`--include-after-body`**: inject raw snippets.
- **Syntax highlighting**: `--highlight-style=tango` (or a custom `.theme`); `--no-highlight` to disable; `--syntax-definition` for custom languages.
- **`--extract-media`**: pull embedded images out of DOCX/EPUB into a folder.

## Common Pitfalls & Troubleshooting
- **"pdflatex not found"** → install a TeX engine or use `--pdf-engine=typst|weasyprint|wkhtmltopdf`.
- **Output is a bare fragment** → add `-s/--standalone`.
- **Citations show as `[@key]`** → forgot `--citeproc` or the `--bibliography`.
- **Extension not working** → it's off in the chosen dialect; enable with `+extension` after the format.
- **Word styles ignored** → provide a `--reference-doc` with the named styles defined.
- **Unicode/Cyrillic broken in PDF** → use `--pdf-engine=xelatex` with `-V mainfont=` set to a Unicode font.
- **Cross-refs unresolved** → install and pass `--filter pandoc-crossref` (order it before `--citeproc`).

## Integration Notes
- **R Markdown** and **Quarto** call Pandoc as their final render step (see r-markdown.md, quarto.md).
- **Static site pipelines** use Pandoc to convert authored Markdown to HTML.
- **CI/publishing**: pair `--defaults` files with Make/Just for reproducible multi-format builds.
- **Zotero/CSL**: `.csl` styles and `.bib`/CSL-JSON libraries drive citation formatting.

## Best For / Avoid For
`document-conversion`, `format-migration`, `academic-writing`, `multi-format-publishing`, `book-generation` — choose Pandoc to move content between formats, add citations, or emit one source as HTML+PDF+DOCX+EPUB.
Avoid for: authoring itself (Pandoc converts, it isn't an editor), precise visual design (use the target's native tools — latex.md, typst.md), or when a purpose-built SSG already wraps Pandoc for you (quarto.md).

## See Also
- `markdown.md`, `restructuredtext.md`, `asciidoc.md` — common Pandoc inputs
- `latex.md`, `typst.md` — PDF engines Pandoc drives
- `quarto.md`, `r-markdown.md` — publishing systems layered on Pandoc
- `docbook.md` — a Pandoc input/output format
- `../use-case/document-processing.md`, `../use-case/document-processing.md`
