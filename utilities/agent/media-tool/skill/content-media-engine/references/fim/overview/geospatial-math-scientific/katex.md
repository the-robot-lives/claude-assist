# KaTeX

## What
KaTeX is a fast, dependency-free JavaScript library for rendering TeX/LaTeX math notation in the browser. Its primary consumer is browser JavaScript (with server-side rendering support), loaded via CDN (`katex.min.css` + `katex.min.js`).

## How
- The LLM emits **LaTeX math strings** plus KaTeX render calls — `katex.renderToString("c = \\pm\\sqrt{a^2 + b^2}", {throwOnError: false})` or `katex.render("E = mc^2", element, {displayMode: true})`.
- The `auto-render` contrib script can typeset a whole page by scanning configured delimiters (`$...$`, `$$...$$`, `\(...\)`, `\[...\]`).
- Custom macros can be supplied (e.g. `\\RR` → `\\mathbb{R}`).
- Typical final artifact: **HTML/CSS-laid-out math** rendered inline in the page (synchronously).

## Why
- Reach for KaTeX when render speed and small footprint matter — it renders synchronously, has no dependencies, is smaller than MathJax, and supports server-side rendering for pre-rendered pages.
- Main tradeoff: it covers a focused (though large) subset of TeX math and lacks MathJax's broader input formats and accessibility/exploration tooling.
- Relative to its siblings: KaTeX is the speed-first math renderer versus `mathjax` (more complete, MathML/accessibility); both take LaTeX math, unlike full `latex`/`tikz-pgf` which compile entire documents/graphics offline.

## Source
- Solution reference: `fim/solution/katex.md`
