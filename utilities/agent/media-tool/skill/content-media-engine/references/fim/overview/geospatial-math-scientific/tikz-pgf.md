# TikZ/PGF

## What
TikZ/PGF is a TeX graphics package for programmatically drawing precise vector figures — shapes, function plots, flowcharts, diagrams — inside a LaTeX document. Its primary consumer is the LaTeX toolchain, which renders the graphics as part of compiling the document to PDF.

## How
- The LLM emits **TikZ/PGF LaTeX source** — `\usepackage{tikz}` (with libraries like `arrows.meta`, `positioning`, `calc`) and `pgfplots`, then `tikzpicture` environments with `\draw`, `\filldraw`, `\node`, and `axis`/`\addplot` for plots.
- That compiles as part of the LaTeX document (e.g. `pdflatex`), producing the figure inline; function plots use `\begin{axis}[domain, samples]` with `\addplot`.
- Typical final artifact: **vector graphics embedded in a PDF** (or standalone via the `standalone` document class).

## Why
- Reach for TikZ when you want publication-quality diagrams that live in the same source as your LaTeX document — consistent fonts and math typesetting, precise coordinates, and function/flowchart drawing without leaving TeX.
- Main tradeoff: it inherits LaTeX's offline compile step and learning curve, and is primarily 2D-oriented.
- Relative to its siblings: TikZ is the in-document figure package for `latex`, whereas `asymptote` is a standalone graphics language with stronger native 3D and general programming; both target precise print-quality figures rather than interactive browser visuals.

## Source
- Solution reference: `fim/solution/tikz-pgf.md`
