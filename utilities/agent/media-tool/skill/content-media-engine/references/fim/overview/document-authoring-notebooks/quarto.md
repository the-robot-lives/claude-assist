# Quarto

## What
Quarto is an open-source scientific and technical publishing system built on Pandoc. It creates dynamic documents with executable Python, R, Julia, and Observable JS code, rendering to dozens of output formats including HTML, PDF, MS Word, and ePub.

## How
- The LLM emits a `.qmd` document: YAML front matter (`title`, `format`, `execute`) plus Markdown with executable ```` ```{python} ```` (or R/Julia/OJS) code fences whose results embed in the output.
- Rendered by the `quarto` CLI (install via `brew` or download); it executes code during rendering and produces the configured format. Also accepts `.md`, `.ipynb`, and `.rmd` inputs.
- Final artifact: HTML, PDF, Word, ePub, reveal.js/Beamer slides, websites, or books.

## Why
- Reach for Quarto for reproducible research, scientific papers/reports, and multi-format publishing where you want multiple languages in one document plus citations, cross-references, equations, and interactive Observable JS widgets.
- Tradeoffs: resource-intensive for large computations during rendering, a learning curve for advanced customization, requires the language runtimes installed, and limited real-time collaboration.
- Versus R Markdown it is the multi-language successor (Python/R/Julia/OJS, not R-centric); versus plain Pandoc it adds code execution and a publishing framework on top.

## Source
- Solution reference: `fim/solution/quarto.md`
