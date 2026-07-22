# TikZ/PGF — programmatic vector graphics for LaTeX

TikZ ("TikZ ist kein Zeichenprogramm") is a LaTeX macro layer over the lower-level PGF engine for producing precise, resolution-independent vector graphics: diagrams, flowcharts, geometric figures, function plots (via pgfplots), circuits, trees, and state machines. Graphics are described declaratively inside `\begin{tikzpicture}...\end{tikzpicture}` and compiled to PDF/DVI/SVG alongside the document, so figures match the document's fonts and math perfectly. For npl-fim, TikZ output is authored as a LaTeX fragment (a `tikzpicture` environment, optionally with a full document preamble) that compiles with `pdflatex`/`lualatex` or `dvisvgm`.

**Current Version**: PGF/TikZ 3.1.x (current major)  **License**: GPL / LPPL (dual)  **Runtime**: LaTeX (`pdflatex`, `lualatex`, `xelatex`); standalone SVG via `dvisvgm` or the `standalone` class

## Official Resources & Documentation
- Manual (the definitive ~1300-page reference): https://tikz.dev/  and https://pgf-tikz.github.io/pgf/pgfmanual.pdf
- pgfplots manual: https://pgfplots.sourceforge.net/pgfplots.pdf
- CTAN: https://ctan.org/pkg/pgf
- GitHub: https://github.com/pgf-tikz/pgf
- Examples gallery: https://texample.net/tikz/examples/  and https://tikz.net/

## Installation & Setup

### TeX distributions (TikZ ships with all major ones)
```bash
# TeX Live (Linux/macOS/Windows)
tlmgr install pgf pgfplots standalone

# MiKTeX auto-installs packages on first use
# macOS: MacTeX bundles everything
```

### Minimal document
```latex
\documentclass{article}
\usepackage{tikz}
\usetikzlibrary{arrows.meta, positioning, calc, shapes.geometric, decorations.pathmorphing}
\usepackage{pgfplots}
\pgfplotsset{compat=1.18}      % pin behavior; avoids version warnings
\begin{document}
\begin{tikzpicture}
  \draw (0,0) -- (2,1);
\end{tikzpicture}
\end{document}
```

### Standalone figure → cropped PDF/SVG (best for embedding)
```latex
\documentclass[tikz,border=2pt]{standalone}   % auto-crops to the graphic
\usetikzlibrary{arrows.meta,positioning,calc}
\begin{document}
\begin{tikzpicture}
  \draw[->] (0,0) -- (2,0);
\end{tikzpicture}
\end{document}
```
```bash
pdflatex figure.tex          # -> figure.pdf (tightly cropped)
# or produce SVG:
latex figure.tex && dvisvgm figure.dvi -o figure.svg
```

## Core Syntax / API Reference

### Coordinates
```latex
(2,3)              % Cartesian, default unit cm
(30:2)            % polar: angle:radius
(a)               % named node's anchor
($ (a) + (1,0) $) % calc: coordinate arithmetic (needs \usetikzlibrary{calc})
(2,3 |- 5,0)      % projection: x of first, y of second
```

### Path operations (the core verbs)
```latex
\path ...;                        % compute a path, draw nothing
\draw (0,0) -- (2,0);            % straight line
\draw (0,0) -- (1,1) -- (2,0);   % polyline
\draw (0,0) -- cycle;            % close the path
\draw (0,0) .. controls (1,2) and (2,2) .. (3,0);  % Bézier
\draw (0,0) to[out=90,in=180] (2,2);               % to with direction
\draw (0,0) circle (1);          % circle radius 1
\draw (0,0) ellipse (2 and 1);   % ellipse rx ry
\draw (0,0) rectangle (2,1);     % rectangle by opposite corners
\draw (0,0) arc (0:90:1);        % arc start:end:radius
\draw (0,0) grid (3,3);          % grid
\draw (1,1) -- +(2,0);           % relative (+, doesn't move pen origin)
\draw (1,1) -- ++(2,0);          % relative (++, moves pen origin)
```

### Draw command family
```latex
\draw   ...;     % stroke
\fill   ...;     % fill only
\filldraw ...;   % fill + stroke
\shade  ...;     % gradient fill
\shadedraw ...;  % gradient + stroke
\node   ...;     % place a node (text/shape)
\coordinate (name) at (x,y);     % a named point
```

### Nodes
```latex
\node[draw, circle, fill=blue!20] (a) at (0,0) {Label};
\node[rectangle, rounded corners, minimum width=2cm] (b) at (3,0) {Box};
% node placed along a path with positioning:
\draw (0,0) -- (4,0) node[midway, above] {edge label}
                     node[at end, right] {end};
```
Common node options: `draw`, `fill`, `circle`/`rectangle`/`ellipse`/`diamond`, `minimum width`/`minimum height`, `inner sep`, `outer sep`, `text width`, `align=center`, `rounded corners`, `anchor=north`.

### Positioning library (relative layout)
```latex
\usetikzlibrary{positioning}
\node (a) {A};
\node (b) [right=of a] {B};             % 'of' respects node distance
\node (c) [below=1cm of a] {C};
\node (d) [above right=of a] {D};
% set default gap:
\begin{tikzpicture}[node distance=1.5cm and 2cm] ... \end{tikzpicture}
```

### Arrows (arrows.meta library)
```latex
\usetikzlibrary{arrows.meta}
\draw[->]  (0,0) -- (1,0);            % default arrow
\draw[-{Stealth}]      (0,0) -- (1,0);
\draw[{Circle}-{Latex[length=3mm]}] (0,0) -- (1,0);
\draw[-{Stealth[scale=1.5]}, thick]  (0,0) -- (1,0);
\draw[<->, dashed] (0,0) -- (1,0);
```

### Styling options (per-path)
```latex
\draw[
  color=red, line width=1.2pt, thick,           % or thin/very thick/ultra thick
  dashed, dotted, dash pattern=on 2pt off 1pt,
  opacity=0.7, fill=blue!20, draw=black,
  rounded corners=3pt, cap=round, join=round
] (0,0) rectangle (2,1);
```

### Reusable styles with \tikzset
```latex
\tikzset{
  block/.style   = {draw, rectangle, rounded corners, minimum height=1cm, align=center},
  decision/.style= {draw, diamond, aspect=2, inner sep=1pt},
  arrow/.style   = {-{Stealth}, thick},
}
\node[block] (a) {Process};
\draw[arrow] (a) -- (b);
```

### Loops & math
```latex
\foreach \x in {0,1,2,3} { \draw (\x,0) circle (2pt); }
\foreach \x/\lbl in {0/a, 1/b, 2/c} { \node at (\x,0) {\lbl}; }
\foreach \i in {1,...,10} { \draw (\i*36:2) -- (\i*36+36:2); }  % step via *
\pgfmathsetmacro{\r}{sqrt(2)}    % compute into a macro
```

## Diagram / Output Types
TikZ + its libraries cover: **flowcharts** (`shapes.geometric`, `positioning`), **trees** (`\node {root} child {...}` or `trees`/`forest`), **graphs/networks** (`graphs`, `graphdrawing`), **state machines/automata** (`automata`), **commutative diagrams** (`cd`), **mind maps** (`mindmap`), **function/data plots** (`pgfplots`: line/scatter/bar/`surf`/`contour`/3D), **circuits** (`circuits.ee`, or CircuiTikZ), **timing diagrams**, **calendars**, **chemistry** (via chemfig), and freeform geometric/technical illustration.

### pgfplots (data & function plotting)
```latex
\begin{tikzpicture}
  \begin{axis}[
    width=10cm, height=6cm,
    xlabel=$x$, ylabel=$y$,
    domain=-3:3, samples=100,
    grid=both, legend pos=north west,
  ]
    \addplot[blue, thick] {x^2};
    \addplot[red, thick]  {sin(deg(x))};   % deg() since pgf trig is in degrees
    \addplot[only marks, mark=*] coordinates {(-2,4) (0,0) (2,4)};
    \addplot table[x=year, y=sales] {data.dat};   % from external data
    \legend{$x^2$, $\sin x$, points, data}
  \end{axis}
\end{tikzpicture}
```

## How-To

### How to add colors, fills & gradients (the styling recipe)
```latex
\usetikzlibrary{shadings}
\definecolor{brandblue}{HTML}{1F77B4}   % define custom named color
\begin{tikzpicture}
  % color!percent mixes with white; color!p!other mixes two colors
  \filldraw[fill=brandblue!30, draw=brandblue, line width=1pt]
    (0,0) rectangle (2,1);
  \filldraw[fill=red!60!black]           (3,0) circle (0.6);
  % gradient fill:
  \shade[left color=yellow, right color=orange] (5,0) rectangle (7,1);
  \shade[inner color=white, outer color=blue!40] (8.5,0.5) circle (0.7);
\end{tikzpicture}
```
`color!NN` lightens toward white; `colorA!p!colorB` mixes; `\definecolor{name}{HTML}{RRGGBB}` (or `{RGB}{r,g,b}`) creates brand colors. Gradients use `\shade`/`\shadedraw` with `left/right/top/bottom/inner/outer color`.

### How to build a flowchart with styled nodes and arrows
```latex
\usetikzlibrary{shapes.geometric, arrows.meta, positioning}
\begin{tikzpicture}[
  node distance=1.4cm,
  block/.style   = {draw, rectangle, rounded corners, minimum width=2.4cm, minimum height=0.9cm, align=center, fill=blue!10},
  decision/.style= {draw, diamond, aspect=2, inner sep=1pt, fill=orange!20},
  arrow/.style   = {-{Stealth[length=2.5mm]}, thick},
]
  \node[block]                       (start) {Start};
  \node[decision, below=of start]    (chk)   {$x>0$?};
  \node[block, below left=of chk]    (no)    {Return $0$};
  \node[block, below right=of chk]   (yes)   {Return $x^2$};
  \draw[arrow] (start) -- (chk);
  \draw[arrow] (chk) -| (no)  node[near start, above] {No};
  \draw[arrow] (chk) -| (yes) node[near start, above] {Yes};
\end{tikzpicture}
```
`-|` / `|-` make right-angle connectors; `near start`/`midway`/`near end` place edge labels.

### How to plot a function and shade the area under it (pgfplots)
```latex
\begin{tikzpicture}
  \begin{axis}[axis lines=middle, xlabel=$x$, ylabel=$y$,
               domain=0:pi, samples=100, ymin=0]
    \addplot[draw=none, fill=blue!20, domain=0:pi] {sin(deg(x))} \closedcycle;
    \addplot[blue, thick, domain=0:pi] {sin(deg(x))};
  \end{axis}
\end{tikzpicture}
```
`\closedcycle` closes the plot to the axis so `fill` shades the region; `deg(x)` converts radians to pgf's degree-based trig.

### How to draw and label geometry with the calc library
```latex
\usetikzlibrary{calc}
\begin{tikzpicture}
  \coordinate (A) at (0,0);
  \coordinate (B) at (4,0);
  \coordinate (C) at (1.5,3);
  \draw (A) -- (B) -- (C) -- cycle;
  \node at ($ (A)!0.5!(B) $) [below] {$c$};   % midpoint via ! syntax
  \fill ($ (A)!0.5!(B)!0.5!(C) $) circle (1.5pt);  % chained interpolation
  \foreach \p/\pos in {A/below left, B/below right, C/above} {
    \fill (\p) circle (1.5pt) node[\pos] {$\p$};
  }
\end{tikzpicture}
```
`($ (A)!t!(B) $)` interpolates a fraction `t` from A to B — the workhorse for geometric construction.

### How to reuse a style across every picture in a document
```latex
% in the preamble:
\tikzset{
  every node/.style={font=\small},
  mynode/.style={draw, circle, minimum size=8mm, fill=green!15},
}
\pgfplotsset{every axis/.append style={grid=major, tick label style={font=\footnotesize}}}
```

## Do's and Don'ts

### ✅ Do
- Always end every path with a semicolon `;` — the single most common TikZ error.
- `\usetikzlibrary{...}` for every feature you use (`positioning`, `calc`, `arrows.meta`, `shapes.geometric`).
- Pin pgfplots: `\pgfplotsset{compat=1.18}` to lock rendering behavior.
- Define reusable `.style`s with `\tikzset` instead of repeating option lists.
- Use the `standalone` class for figures you'll embed elsewhere — it auto-crops.
- Use `deg()` inside pgfplots trig (`sin(deg(x))`) — pgf trig defaults to degrees.

### ❌ Don't
- Don't forget the terminating `;` — TikZ will consume the next line and emit a cryptic error.
- Don't use `right of=a` (old `of` without `positioning`) mixed with `right=of a`; the library form `right=of a` respects `node distance`. Load `positioning` and use it consistently.
- Don't rely on `pdflatex` for a `.dvi` SVG path — SVG via `dvisvgm` needs the `latex`→`dvi` route (or `dvisvgm --pdf`).
- Don't put raw `%`, `#`, `_`, `&` in node text — escape them (`\%`, `\_`) or they break compilation.
- Don't use enormous `samples=` counts unnecessarily — pgfplots is CPU-bound at compile time and can time out.
- Don't invent a `graph.toTikZ()` JS API — TikZ is authored as LaTeX source; generate the `\node`/`\draw` lines directly.

## Styling, Theming & Customization
- **Colors**: named (`red`, `blue`), mixes (`blue!30`, `red!60!black`), custom `\definecolor{name}{HTML}{1F77B4}` / `{RGB}{31,119,180}`. Load `xcolor` (auto-loaded by tikz) for the `dvipsnames`/`svgnames` palettes.
- **Line styles**: `thin`/`thick`/`ultra thick`, `line width=1pt`, `dashed`, `dotted`, `dash pattern=on 3pt off 2pt`, `cap=round`, `join=bevel`.
- **Fills & gradients**: `fill`, `\shade[...]`, `pattern=north east lines` (needs `patterns` library), `opacity`/`fill opacity`.
- **Global theming**: `\tikzset{every node/.style={...}}`, `\pgfplotsset{every axis/.append style={...}}`, or a shared preamble style file.
- **pgfplots colormaps**: `colormap/viridis`, `colormap/jet`; `\addplot3[surf]` respects the axis `colormap`.
- **Fonts** inherit from the document — that's the point: figure text matches body text automatically.

## Advanced Features
- **Layers** (`\pgfdeclarelayer`/`\pgfsetlayers`) to draw backgrounds behind nodes; `backgrounds` library provides `on background layer`.
- **Decorations**: `decorations.pathmorphing` (snake/coil/zigzag lines), `decorations.markings` (place arrows/marks along a path), `decorations.text`.
- **Scoping & transforms**: `\begin{scope}[shift={(2,0)}, rotate=30, scale=1.5] ... \end{scope}`.
- **externalize** library caches each picture to its own PDF so recompiles are fast: `\usetikzlibrary{external}\tikzexternalize`.
- **3D**: pgfplots `\addplot3`, `axis` with `view={az}{el}`; `tikz-3dplot` for 3D coordinate frames.
- **Automata/graphs**: `automata` library for state machines; `graphdrawing` (needs LuaLaTeX) for automatic layout.
- **Animations**: the `animate` library (PGF 3.1+) produces PDF/SVG animations.

## Common Pitfalls & Troubleshooting
- **Missing semicolon** → "Package tikz Error: ... " swallowing following content. Check the path before the error line.
- **Dimension too large**: coordinates/products exceed TeX's ~16384pt limit — scale down units or use `pgfplots` which manages this.
- **pgf trig in degrees**: `sin(x)` treats `x` as degrees; wrap radians with `deg()`.
- **Overlapping nodes**: increase `node distance`, `minimum size`, or `inner sep`; use `positioning` not manual `at`.
- **SVG output missing**: use `latex`+`dvisvgm` (not `pdflatex`) or `dvisvgm --pdf figure.pdf`.
- **Slow compiles**: enable `\tikzexternalize`, lower `samples`, or precompile figures to PDF and `\includegraphics` them.
- **Colors look off in print**: HTML/RGB colors are screen sRGB; for CMYK print define with `{cmyk}{...}`.

## Integration Notes
- **LaTeX documents**: drop the `tikzpicture` inline; it uses document fonts/math for seamless figures.
- **Markdown/web**: compile a `standalone` figure to SVG (`dvisvgm`) or PNG and embed.
- **Pandoc/Quarto**: TikZ blocks can be rendered to images via filters (`rawtikz`, `diagram` extensions).
- **CircuiTikZ / chemfig / tikz-cd**: domain libraries built on TikZ for EE schematics, chemistry, and category-theory diagrams.
- **matplotlib bridge**: `matplotlib2tikz`/`tikzplotlib` exports matplotlib figures to pgfplots for font-matched inclusion.

## Best For / Avoid For
`latex-figures`, `precise-vector`, `diagrams`, `flowcharts`, `function-plots`, `technical-illustration`, `publication` — choose TikZ when the figure lives in a LaTeX document and must match its typography, or when you need exact, reproducible, version-controllable vector graphics.

Avoid for: interactive/animated web graphics (use D3/SVG/JS), quick data dashboards (Plotly/Dash), or when no LaTeX toolchain is available and a one-off raster would do.

## See Also
- `metapost.md` — sibling declarative graphics language with an equation solver
- `sympy.md` / `sagemath.md` — generate `latex()` expressions to typeset inside TikZ nodes
- `graphviz.md`, `plantuml.md` — automatic-layout diagram alternatives when manual placement is overkill
- `../use-case/mathematical-notation.md`, `../use-case/technical-diagrams.md`
