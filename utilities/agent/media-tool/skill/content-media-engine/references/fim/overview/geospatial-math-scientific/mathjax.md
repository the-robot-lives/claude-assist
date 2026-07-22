# MathJax

## What
MathJax is a JavaScript library for rendering TeX, LaTeX, and MathML notation in the browser, with strong accessibility support. Its primary consumer is browser JavaScript, loaded via CDN (MathJax 3, `tex-mml-chtml.js`).

## How
- The LLM emits **LaTeX/MathML math** in the page plus optional MathJax config — `window.MathJax = {tex: {inlineMath, displayMath, processEscapes}, svg: {fontCache}}`.
- On load MathJax typesets delimited math (`$...$`, `$$...$$`, `\(...\)`, `\[...\]`); dynamically added content is rendered with `MathJax.typesetPromise([element])`, and MathML can be converted via `MathJax.mathml2chtml(...)`.
- Typical final artifact: **rendered math in the page** (CHTML or SVG output) with automatic MathML for assistive tech.

## Why
- Reach for MathJax when completeness and accessibility matter — broad TeX/MathML input coverage, automatic MathML generation, screen-reader support, keyboard navigation, and an expression explorer.
- Main tradeoff: it is larger and renders asynchronously, so it is slower to first paint than KaTeX.
- Relative to its siblings: MathJax is the accessibility- and coverage-first math renderer versus the speed-first `katex`; both render fragments client-side, unlike the offline document/graphics tools `latex`/`tikz-pgf`.

## Source
- Solution reference: `fim/solution/mathjax.md`
