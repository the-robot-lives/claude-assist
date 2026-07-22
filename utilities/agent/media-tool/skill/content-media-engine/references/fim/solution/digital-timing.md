# Digital Timing Diagrams — Toolchains & the tikz-timing Grammar

"Digital timing diagram" names a *category* of tools that draw clocked signals,
buses, and protocol handshakes. Three families dominate: **WaveDrom/WaveJSON**
(JSON → SVG, browser-friendly), **tikz-timing** (LaTeX → PDF/PDF-SVG, publication
quality), and small Python generators. This file focuses on the LaTeX-native
`tikz-timing` grammar and on choosing between the families; WaveDrom has its own
reference in `wavedrom.md`.

**Primary engines**: `tikz-timing` (LaTeX, current), WaveDrom 3.x (JS)
**License**: tikz-timing LPPL; WaveDrom MIT  **Output**: PDF/SVG/PNG

## Official Resources & Documentation
- tikz-timing CTAN: https://ctan.org/pkg/tikz-timing (manual PDF included)
- tikz-timing source: https://github.com/derwolfe/tikz-timing (mirror) / CTAN
- WaveDrom: https://wavedrom.com/ — see `wavedrom.md`
- Undulate (Python WaveJSON renderer): https://github.com/LudwigCRON/undulate
- Comparison / examples: https://tikz.net/ (timing category)

## Installation & Setup

### tikz-timing (LaTeX)
```bash
tlmgr install tikz-timing          # TeX Live
# then in the preamble:
```
```latex
\usepackage{tikz}
\usepackage{tikz-timing}
```
Compile with `pdflatex`; convert PDF→SVG with `pdf2svg` or `dvisvgm` if needed.

### WaveDrom (JS/CLI) — alternative
```bash
npm install -g wavedrom-cli
```

### Python generators
```bash
pip install undulate           # renders WaveJSON to SVG/CairoSVG/TikZ
```

## Core Syntax / API Reference — tikz-timing

### Two authoring modes
```latex
% 1) Inline: a single timing string
\begin{tikztiming}
  L H 2L 2{H L} Z X D{bus}
\end{tikztiming}

% 2) Aligned table: named rows share a timebase
\begin{tikztimingtable}
  Clock  & 10{C}                         \\
  Data   & 2D{Valid} 2U 3D{New} 3Z       \\
  Enable & L H 6L H L                     \\
\end{tikztimingtable}
```

### Signal character alphabet
Each letter is a logic segment; a leading number sets its duration in units.

| Token | Meaning |
|-------|---------|
| `L` | logic low |
| `H` | logic high |
| `Z` | high impedance (mid line) |
| `X` | unknown / don't-care (hatched) |
| `D` | data / bus (both rails); `D{text}` labels it |
| `U` | undefined level segment |
| `T` | toggling / transition |
| `C` | one clock half-unit (use `10{C}` for a clock train) |
| `G` | glitch |
| `N` | noise |

### Durations, repetition, and labels
```latex
2L          % low for 2 units
2{H L}      % repeat the group "H L" twice
D{0xF0}     % data segment carrying the text 0xF0
3D{Addr}    % 3-unit-wide labeled bus segment
```

### Per-segment options in brackets
```latex
L [rounded corners] H          % local style tweak
D{data} [red] Z                % color one segment
```

### Table styling and rules
```latex
\begin{tikztimingtable}[
    timing/slope=0.1,             % edge slant (0 = vertical)
    timing/coldist=2pt,           % gap between columns
    x=6mm, y=8mm                  % unit scale
  ]
  \tableheader{Signal & Waveform} \\   % optional header row (custom macro)
  Clk & 8{C} \\
\extracode
  \begin{pgfonlayer}{background}
    \vertlines[help lines]{2,4,6}      % reference grid lines
  \end{pgfonlayer}
\end{tikztimingtable}
```

### Arrows & annotations (between edges)
Use the `\extracode` block plus named nodes to draw setup/hold arrows:
```latex
\begin{tikztimingtable}
  D & 2L 2H 2L [name=d] \\
  C & 4{C}       [name=c] \\
\extracode
  \draw[->] (d) -- node[above]{$t_{su}$} (c);
\end{tikztimingtable}
```

## Diagram / Output Types
- **Clocked timing** — clock trains via `{C}`, data via `D{...}`.
- **Bus transactions** — labeled `D` segments with `X`/`Z` gaps.
- **Handshakes** — multiple aligned rows (req/ack/valid/ready).
- **Register/field** timing when combined with tabular labels.
For JSON-first, browser-embeddable versions of the same, use WaveDrom.

## How-To (worked recipes)

### How to draw a clock and a labeled data bus in step
```latex
\begin{tikztimingtable}
  CLK  & 8{C}                       \\
  DATA & X 2D{0x3A} 2D{0x3B} 2X X   \\
\end{tikztimingtable}
```
`{C}` builds the clock; `D{...}` bus cells change on clock boundaries.

### How to color / style segments (the "add color" recipe)
Bracketed TikZ options after a segment restyle just that segment; a table-wide
option restyles everything:
```latex
\begin{tikztimingtable}[timing/d/background/.style={fill=blue!12}]
  BUS & D{idle} [fill=green!20] 2D{active} [fill=red!20] D{err} \\
\end{tikztimingtable}
```
`timing/d/background/.style` recolors every data cell; per-segment `[fill=...]`
overrides individual ones.

### How to add reference grid lines / cycle markers
```latex
\begin{tikztimingtable}
  S & 6{C} \\
\extracode
  \begin{pgfonlayer}{background}
    \vertlines[help lines, gray]{1,2,3,4,5,6}
  \end{pgfonlayer}
\end{tikztimingtable}
```

### How to annotate a setup-time arrow
```latex
\begin{tikztimingtable}
  D & 3L 3H [name=de] \\
  C & 6{C}  [name=ck] \\
\extracode
  \draw[<->, red] (de) -- node[fill=white]{$t_{su}$} (ck);
\end{tikztimingtable}
```

### How to render the same diagram as SVG for the web
Author WaveJSON instead and run `wavedrom-cli`, or convert the LaTeX PDF:
```bash
pdflatex timing.tex && pdf2svg timing.pdf timing.svg
```

## Do's and Don'ts

### ✅ Do
- Choose one engine per document: tikz-timing for print/PDF, WaveDrom for web.
- Use numeric multipliers (`6L`) instead of repeating letters (`LLLLLL`).
- Keep all table rows on the same total unit count so columns align.
- Wrap data payloads in braces: `D{0xFF}`, not `D 0xFF`.
- Put arrows/grid in the `\extracode` block, not inline with signals.

### ❌ Don't
- Don't hand-place PDF pixels — let the unit grid (`x=`,`y=`) do layout.
- Don't mix `C` clock segments with manual `H`/`L` toggling on one clock row.
- Don't forget `\usepackage{tikz-timing}` (and `tikz`) — cryptic errors follow.
- Don't expect analog ramps; these are logic-level tools (use SPICE plots).
- Don't nest `tikztimingtable` inside another; use one table per figure.

## Styling, Theming & Customization
- **Global scale**: `x=`/`y=` lengths set unit width/height; `timing/slope`
  controls edge slant (0 for crisp verticals, up for stylized transitions).
- **Colors**: per-segment `[fill=...]`/`[draw=...]`, or restyle a class with
  `timing/d/background/.style`, `timing/l/.style`, etc.
- **Fonts/labels**: data labels inherit the surrounding LaTeX font; use math
  mode `D{$t_0$}` for subscripts.
- **Grid**: `\vertlines`/`\horlines` on the background layer for references.
- WaveDrom equivalent styling is skin-based (`config.skin`) — see `wavedrom.md`.

## Advanced Features
- **`\extracode` layer** — arbitrary TikZ (braces, arrows, dimension lines).
- **Custom characters** — define new segment letters with `\tikztimingmetachar`.
- **Character metafont reuse** — `2{C}` clock groups, nested `{ }` repetition.
- **Undulate** bridges the worlds: it reads WaveJSON and can emit TikZ for LaTeX.

## Common Pitfalls & Troubleshooting
- **Rows misalign** → unit counts differ across rows; recount durations.
- **Data text collides** → segment too narrow; widen with a larger multiplier
  or increase `x=`.
- **"Undefined control sequence"** → missing `\usepackage{tikz-timing}`.
- **Slanted edges unwanted** → set `timing/slope=0`.
- **Web embed needed** → tikz-timing outputs PDF; switch to WaveDrom/WaveJSON
  rather than rasterizing.

## Integration Notes
- LaTeX/Overleaf render tikz-timing natively; Markdown does not — pre-bake SVG.
- For docs sites, prefer WaveDrom (SVG in the browser). For IEEE/ACM papers,
  prefer tikz-timing (vector, font-consistent with the body text).

## Best For / Avoid For
`latex-papers`, `datasheets`, `print-timing`, `protocol-handshakes` — tikz-timing
when the diagram lives in a LaTeX document; WaveDrom when it lives on the web.
Avoid both for analog/mixed-signal traces (use SPICE transient plots) and for
free-form sequence charts (use a sequence-diagram tool).

## See Also
- [wavedrom.md](wavedrom.md) — JSON→SVG timing, the web-native path
- [wavejson.md](wavejson.md) — the interchange format
- [circuitikz.md](circuitikz.md) — TikZ schematics that pair with tikz-timing
- [spice-netlist.md](spice-netlist.md) — analog counterpart (transient plots)
- ../use-case/engineering-diagrams.md
