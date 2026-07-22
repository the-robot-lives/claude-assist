# LaTeX

## What
LaTeX is a document preparation system and markup language for producing typeset documents, especially those with heavy mathematics. Its primary consumer is a local LaTeX toolchain (TeX Live / MacTeX) that compiles source to PDF.

## How
- The LLM emits **LaTeX document source** (`.tex`) — `\documentclass{...}`, `\usepackage{...}`, and body markup with math environments (`\[ ... \]`, `$...$`, `bmatrix`, etc.).
- That is compiled with `pdflatex document.tex`; documents with citations run `pdflatex` → `bibtex` → `pdflatex` → `pdflatex` to resolve references.
- Common packages extend it: `amsmath` (math), `tikz` (graphics), `listings` (code), `hyperref` (links), `graphicx` (images).
- Typical final artifact: a **PDF** (publication-ready typeset document).

## Why
- Reach for LaTeX when the deliverable is a full typeset document — papers, books, reports — with rigorous math, cross-references, and bibliography management.
- Main tradeoff: it requires a full local toolchain install and an offline compile step, and is document-scale rather than a snippet renderer.
- Relative to its siblings: LaTeX is the whole-document system; `katex`/`mathjax` render just math fragments in the browser, and `tikz-pgf`/`asymptote` produce figures (TikZ living inside a LaTeX document, Asymptote as a standalone language).

## Source
- Solution reference: `fim/solution/latex.md`
- Nested use-case detail: `fim/solution/latex/use-case/document-processing.md`, `fim/solution/latex/use-case/mathematical-scientific.md`
