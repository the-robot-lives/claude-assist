# MetaPost

## What
A graphics description language (part of the TeX ecosystem) for producing precise, resolution-independent figures via declarative path definitions, transformations, and mathematical plotting. Its consumer is the `mpost` compiler; output is vector figures (PostScript/PDF, convertible to SVG).

## How
- The LLM emits a `.mp` MetaPost program: `beginfig(1); ... endfig;` blocks defining paths (`path p; p := (0,0)--(2u,0)--(1u,1.5u)--cycle;`), `fill`/`draw` with pens and colors, bezier curves (`(0,0){right}..(1cm,2cm){up}..`), loops for transformed copies, and `label`/`dotlabel` annotations.
- Compile with `mpost figure.mp`, which emits `figure.1`, `figure.2`, … (one per `beginfig`). Convert to web-friendly SVG via a PDF step (`mpost --tex=latex ...` then `pdf2svg figure.pdf figure.svg`). MetaPost usually ships with a TeX install (`texlive-metapost`).
- Typical final artifact: a crisp vector figure — geometric diagrams, function plots with grids, technical illustrations — suited for print/PDF and LaTeX documents.

## Why
- Reach for MetaPost when you need mathematically exact, publication-quality technical figures with LaTeX-native typesetting of labels, driven by programmatic path/curve math and loops.
- Limitations: it is a batch compile-to-file toolchain, not an interactive or browser-native library — no animation, no live interaction, and web use requires a compile-and-convert pipeline; the language is niche and syntactically distinct from mainstream tooling.
- Relative to siblings: metapost is the odd one out in this category — a TeX-world, print-oriented, declarative vector language rather than a browser JS library. Choose it when the target is a LaTeX/PDF document and precision matters; choose the Canvas/SVG JS libraries here when the target is the web.

## Source
- Solution reference: `fim/solution/metapost.md`
