# CircuiTikZ

## What
CircuiTikZ is a LaTeX package that extends TikZ with specialized circuit-drawing capabilities for producing publication-quality electronic circuit schematics. The LLM emits LaTeX/TikZ markup that compiles to vector output; its primary consumer is a LaTeX toolchain (pdflatex + document), making it a natural fit for academic papers, patents, and textbooks.

## How
- **LLM emits:** LaTeX source inside a `\begin{circuitikz} ... \end{circuitikz}` environment, using `to[R=10k]`, `to[C=100n]`, `node[op amp]`, etc. — coordinate-based component placement with IEEE/IEC symbols.
- **Render path:** wrap in a document that loads `\usepackage[american]{circuitikz}` (or `[european]`), then compile with `pdflatex circuit.tex`. For web output, convert the PDF with `pdf2svg circuit.pdf circuit.svg` or Inkscape. A `standalone` documentclass with `border=5mm` yields a tightly-cropped figure.
- **Typical final artifact:** PDF (native) or SVG (via conversion).

## Why
- **Reach for it when:** the circuit lives inside a LaTeX document and needs typography/math consistency with the surrounding text, precise coordinate control, and a large (500+ symbol) IEEE/IEC-standard component library with inline equation annotations.
- **Limitations:** hard LaTeX dependency, a steep TikZ learning curve, non-trivial compilation time for complex circuits, and no interactivity.
- **Relative to siblings:** unlike SchemDraw (Python/programmatic) or the native EDA tools (KiCad/Fritzing), CircuiTikZ is the choice when the deliverable is a typeset document rather than a manufacturable board — it draws schematics for print, it does not do PCB layout or simulation.

## Source
- Solution reference: `fim/solution/circuitikz.md`
- Nested use-case detail: `fim/solution/circuitikz/use-case/engineering-diagrams.md`
