# Typst

## What
Typst is a modern markup-based typesetting system designed as a LaTeX alternative, with an intuitive backslash-free syntax and a built-in scripting language. It targets high-quality documents with math, tables, and figures.

## How
- The LLM emits Typst markup (`.typ`): `#set` configuration rules, `=` headings, inline/block math (`$E = m c^2$`, `mat(...)`), and `#figure`/`#table` functions.
- Compiled with the `typst` CLI: `typst compile document.typ` for PDF, `typst watch document.typ` for live incremental preview, or `typst compile document.typ output.png --format png`; installs via `brew` or binary download, with a web editor at typst.app.
- Final artifact: PDF (primary), or PNG.

## Why
- Reach for Typst for academic papers, theses, technical documentation, slides, and mathematical documents where you want LaTeX-quality output with far faster compilation (cited as 10-100x), modern syntax, live preview, and clear error messages.
- Tradeoffs: newer/smaller package ecosystem than LaTeX, cannot reuse LaTeX templates directly, less mature bibliography/citation management, and still gaining journal acceptance.
- It is the modern challenger to LaTeX in this category; versus Pandoc/Quarto it is a direct typesetting engine rather than a multi-format converter.

## Source
- Solution reference: `fim/solution/typst.md`
