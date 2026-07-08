# Asymptote

## What
Asymptote is a descriptive vector graphics **programming language** for technical drawing and mathematical/scientific illustration, inspired by MetaPost with native LaTeX integration. Its primary consumer is the Asymptote toolchain (`asy` compiler), which produces publication-quality 2D and 3D figures.

## How
- The LLM emits **Asymptote source** (`.asy`) — an object-oriented, math-aware program describing the figure (paths, labels, 3D surfaces, parametric curves).
- That is compiled with the `asy` command: `asy filename.asy`, or with an explicit format flag — `asy -f pdf`, `asy -f svg`, `asy -f png`, `asy -f html` (HTML5/WebGL for interactive 3D).
- LaTeX (e.g. texlive) is required for mathematical typesetting.
- Typical final artifact: a **PDF/EPS/SVG/PNG** figure, or an interactive **HTML5+WebGL** 3D view.

## Why
- Reach for Asymptote when you need mathematically precise, publication-grade figures with perfect LaTeX typography — journal diagrams, physics/engineering illustrations, geometric proofs, textbook figures, and true 3D with lighting.
- Limitations: steep learning curve (it is a real programming language), a hard LaTeX dependency, significant compilation time and memory for complex 3D, limited real-time/GUI editing, and a smaller community with documentation gaps.
- Relative to its siblings: Asymptote is the standalone-language counterpart to `tikz-pgf` (which lives inside a LaTeX document); both target precise publication figures, but Asymptote has stronger native 3D and programmability, while `mathbox` targets interactive browser 3D instead of print.

## Source
- Solution reference: `fim/solution/asymptote.md`
