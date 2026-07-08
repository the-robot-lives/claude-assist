# CircuiTikZ — Publication-Quality Circuit Schematics in LaTeX

CircuiTikZ is a LaTeX package built on TikZ for drawing electrical circuits as
vector graphics. You describe a circuit as paths of two-terminal "bipoles"
(resistors, capacitors, sources…) and placed multi-terminal nodes (transistors,
op-amps, gates), and LaTeX typesets a crisp PDF/SVG that matches your document's
fonts and math. It is the standard for textbooks, papers, and lecture notes.

**Current Version**: circuitikz 1.x (current major)  **License**: LPPL / GPL
**Runtime**: LaTeX (pdflatex/lualatex/xelatex) → PDF; SVG via dvisvgm/pdf2svg

## Official Resources & Documentation
- CTAN: https://ctan.org/pkg/circuitikz (the ~600-page manual PDF)
- GitHub: https://github.com/circuitikz/circuitikz
- Examples gallery: https://tikz.net/ (circuit category), https://circuitikz.github.io/
- TikZ manual (host language): https://ctan.org/pkg/pgf
- Q&A: https://tex.stackexchange.com/questions/tagged/circuitikz

## Installation & Setup

### TeX distribution
```bash
tlmgr install circuitikz            # TeX Live
# Debian/Ubuntu: apt-get install texlive-pictures
```

### Preamble
```latex
\documentclass{article}
\usepackage[siunitx, RPvoltages]{circuitikz}  % package options (below)
\begin{document}
\begin{circuitikz}[american]
  \draw (0,0) to[R=$R_1$] (2,0) to[C=$C_1$] (2,-2)
        to[battery1] (0,-2) -- (0,0);
\end{circuitikz}
\end{document}
```

### Package options (set behavior globally)
`americanresistors` / `europeanresistors`, `cuteinductors` / `americaninductors`,
`americanports` / `europeanports` (logic gates), `siunitx` (units in labels),
`smartlabels`, `RPvoltages` (raise voltage arrows), `betterproportions`.

## Core Syntax / API Reference

### The path model
```latex
\draw (x1,y1) to[<bipole>=<label>] (x2,y2) to[...] (x3,y3);
```
- Coordinates may be absolute `(2,0)`, relative `++(2,0)`, or named `(A.out)`.
- `--` draws a plain wire; `to[short]` is a wire that can carry labels/current.
- Chain multiple `to[...]` segments in one `\draw` for a connected path.

### Two-terminal components (bipoles)
Placed with `to[<key>]`. Common keys:

| Key | Component |
|-----|-----------|
| `R` / `european resistor` | resistor |
| `C` / `capacitor`, `eC` | capacitor / electrolytic |
| `L` / `cute inductor` | inductor |
| `D`, `leD`, `zD`, `sD`, `tD` | diode / LED / Zener / Schottky / tunnel |
| `battery1`, `battery2`, `battery` | battery cells |
| `V`, `sV`, `american voltage source` | voltage source (DC / sinusoidal) |
| `I`, `sI`, `american current source` | current source |
| `short`, `open` | wire / gap |
| `switch`, `nos`, `ncs`, `spdt` | switches |
| `lamp`, `buzzer`, `fuse`, `ammeter`, `voltmeter` | misc |

### Labels, values, annotations
```latex
\draw (0,0) to[R=$R_1$] (2,0);           % value on default side
\draw (0,0) to[R, l=$R_1$] (2,0);        % explicit label
\draw (0,0) to[R, l_=$R_1$] (2,0);       % label on the other side
\draw (0,0) to[R, a=$1\%$] (2,0);        % annotation (opposite side)
\draw (0,0) to[C=\SI{100}{\nano\farad}] (2,0);  % siunitx value
```
- `l=` label, `l^`/`l_` force the above/below (or left/right) side.
- `a=` secondary annotation drawn opposite the label.

### Currents, voltages, flows
```latex
\draw (0,0) to[R=$R_1$, i=$i_1$, v=$v_R$] (2,0);
\draw (0,0) to[R, i>_=$i$] (2,0);   % current arrow direction/side
\draw (0,0) to[R, v^>=$v$] (2,0);   % voltage arrow direction/side
\draw (0,0) to[L, f=$\phi$] (2,0);  % flow arrow
```

### Named components & connection dots
```latex
\draw (0,0) to[R=$R_1$, name=R1] (2,0) node[circ]{};   % filled junction
\draw (2,0) node[ocirc]{};                              % open terminal
% later reference an anchor:
\draw (R1.center) -- ++(0,-1) node[ground]{};
```
`node[circ]` = solid dot (connection), `node[ocirc]` = open circle (terminal).

### Multi-terminal nodes
```latex
% Op-amp
\draw (0,0) node[op amp] (A){};
\draw (A.-) -- ++(-1,0);  \draw (A.+) -- ++(-1,0);  \draw (A.out) -- ++(1,0);

% Transistors (anchors .gate/.drain/.source or .base/.collector/.emitter)
\draw (0,0) node[nmos] (M1){};
\draw (M1.gate) -- ++(-1,0);
\draw (0,0) node[npn]  (Q1){};

% Ground / supply
\draw (0,0) node[ground]{};  \draw (0,2) node[vcc]{$V_{CC}$};
```

### Logic gates (ports)
```latex
\draw (0,0) node[and port]  (X){};
\draw (0,-2) node[not port] (Y){};
\draw (X.out) -- (Y.in 1);
% anchors: .in 1, .in 2, .out ; types: and/or/not/nand/nor/xor/xnor/buffer port
```

## Diagram / Output Types
- **Analog schematics** — RLC networks, filters, amplifiers, power supplies.
- **Transistor-level** — MOS/BJT stages with proper symbols and anchors.
- **Digital logic** — gate networks (american/european port styles).
- **Block/signal** — mixers, amplifiers (`amp`), ADC/DAC boxes.
- **Instrumentation** — meters, sources, switches, connectors.

## How-To (worked recipes)

### How to color components and wires (the "add color" recipe)
Bracketed options after `to[` accept ordinary TikZ styles, and `\draw[color]`
tints a whole path:
```latex
\begin{circuitikz}
  \draw[blue]     (0,0) to[R=$R_1$] (2,0);       % whole path blue
  \draw (0,0) to[C=$C_1$, red] (0,-2);           % single bipole red
  \draw (0,0) to[L=$L_1$, color=green!60!black] (2,-2);
\end{circuitikz}
```
For fills, target the style: `\ctikzset{bipoles/fill=yellow!20}`.

### How to draw a labeled RC low-pass filter
```latex
\begin{circuitikz}[american]
  \draw (0,0) node[left]{$v_{in}$}
        to[R=$R$] (3,0)
        to[C=$C$] (3,-2) node[ground]{};
  \draw (3,0) to[short, -o] (4,0) node[right]{$v_{out}$};
\end{circuitikz}
```

### How to add voltage and current annotations
```latex
\begin{circuitikz}
  \draw (0,0) to[V=$V_s$, invert] (0,2)
        to[R=$R_1$, i>^=$i_1$, v=$v_1$] (3,2)
        to[R=$R_2$, v=$v_2$] (3,0) -- (0,0);
\end{circuitikz}
```

### How to scale a schematic without distorting labels
```latex
\begin{circuitikz}[scale=1.3, transform shape]
  \draw (0,0) to[R] (2,0) to[C] (2,-2);
\end{circuitikz}
```
`transform shape` scales node symbols too; omit it to scale only coordinates.

### How to place a transistor amplifier stage
```latex
\begin{circuitikz}
  \draw (0,0) node[npn] (Q){};
  \draw (Q.base)      to[R=$R_B$] ++(-2,0) node[left]{in};
  \draw (Q.collector) to[R=$R_C$] ++(0,2)  node[vcc]{$V_{CC}$};
  \draw (Q.emitter)   -- ++(0,-1) node[ground]{};
\end{circuitikz}
```

## Do's and Don'ts

### ✅ Do
- Build circuits as continuous `\draw ... to[...] ...` chains; branch with new
  `\draw` statements from named anchors.
- Use `node[circ]{}` at every genuine junction so crossing wires read correctly.
- Set a house style once with `\ctikzset{}` / package options, not per-component.
- Use `siunitx` values (`\SI{10}{\kilo\ohm}`) for consistent unit typesetting.
- Name components (`name=Q1`) when you need to draw to their anchors later.

### ❌ Don't
- Don't rely on wire crossings implying a connection — add `node[circ]` or route
  around; unmarked crossings are read as *no* connection.
- Don't hardcode magic coordinates everywhere; use relative `++(dx,dy)`.
- Don't mix american and european symbol options randomly — pick one per figure.
- Don't forget the trailing `;` on each `\draw` (a classic compile error).
- Don't scale with `scale=` alone if symbols look wrong — add `transform shape`.

## Styling, Theming & Customization
- **`\ctikzset{...}`** is the central knob: `resistors/scale=0.8`,
  `bipoles/length=1.2cm`, `voltage=american|european`, `label/align=straight`,
  `bipoles/fill=...` for filled bodies.
- **Colors** via TikZ `\draw[<color>]` (whole path) or `to[R, <color>]` (one
  component); fills via `\ctikzset{...fill=...}`.
- **American vs European** styling toggled per package option or per environment
  (`[american]` / `[european]`).
- **Line width / font** inherit from TikZ (`line width=0.8pt`) and the document.

## Advanced Features
- **Currents/voltages/flows** with full arrow-direction control (`i>`, `v_`, `f<`).
- **Custom bipoles** by defining new `to[...]` shapes via `\ctikzset`.
- **Coupling & transformers**, **potentiometers** (`pR`), **crossings** (`\draw
  (a) to[short] (b);` with `jump crossing`).
- **Integration with pgfplots** to overlay measured curves next to schematics.
- **externalize** TikZ to cache compiled figures and speed large documents.

## Common Pitfalls & Troubleshooting
- **Wires seem disconnected** → missing junction dots; add `node[circ]{}`.
- **Labels on the wrong side** → use `l_`/`l^` or `v_`/`v^` to force the side.
- **Symbols overlap** → increase `bipoles/length` or space coordinates further.
- **`Missing $ inserted`** → math in a label without `$...$`.
- **Huge compile time** → enable TikZ `externalize` library to cache figures.
- **SVG needed** → compile PDF then `dvisvgm`/`pdf2svg`; there is no direct SVG.

## Integration Notes
- Native in LaTeX/Overleaf; not renderable in plain Markdown — export SVG/PDF.
- Pairs naturally with `tikz-timing` (timing) and `pgfplots` (measured data) in
  the same document with a unified look.

## Best For / Avoid For
`latex-schematics`, `textbooks`, `papers`, `analog`, `transistor-level` — choose
CircuiTikZ when the schematic lives in a LaTeX document and must match its
typography. Avoid for interactive/web schematics (use SchemDraw→SVG or KiCad)
and for board layout / manufacturing (use KiCad or Fritzing).

## See Also
- [schemdraw.md](schemdraw.md) — Python analogue, direct SVG/PNG output
- [kicad.md](kicad.md) — full EDA capture + PCB when you need manufacturing
- [digital-timing.md](digital-timing.md) — tikz-timing waveforms for the same doc
- [lcapy.md](lcapy.md) — draws schematics *and* solves them symbolically
- ../use-case/engineering-diagrams.md
