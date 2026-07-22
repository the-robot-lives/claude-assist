# Lcapy — Symbolic Linear Circuit Analysis in Python

Lcapy analyzes linear electrical circuits *symbolically* (via SymPy) and draws
them (via CircuiTikZ). From a netlist or composable network objects you get
exact transfer functions, impedances, and time/Laplace/frequency responses as
algebraic expressions — plus publication-quality schematics and Bode/pole-zero
plots. It is the tool of choice when you need the *formula*, not just a number.

**Current Version**: lcapy 1.2x+ (current)  **License**: LGPL v2.1
**Runtime**: Python 3.8+; SymPy, NumPy, Matplotlib; LaTeX+CircuiTikZ for drawing

## Official Resources & Documentation
- Docs: https://lcapy.readthedocs.io/
- GitHub: https://github.com/mph-/lcapy
- PyPI: https://pypi.org/project/lcapy/
- Tutorials: https://lcapy.readthedocs.io/en/latest/tutorials.html
- Novice guide: https://lcapy.readthedocs.io/en/latest/novice.html

## Installation & Setup
```bash
pip install lcapy
pip install "lcapy[plotting]"          # ensure matplotlib
# For schematic drawing you also need LaTeX + circuitikz + a PDF->image tool:
sudo apt-get install texlive-latex-extra texlive-pictures pdf2svg imagemagick
```

### Minimal analysis
```python
from lcapy import Circuit
cct = Circuit("""
V 1 0 dc 5
R 1 2 10k
C 2 0 100n
""")
H = cct.transfer(1, 0, 2, 0)           # transfer function V(2,0)/V(1,0)
print(H)                                # symbolic H(s)
cct.draw('rc.svg')                      # render the schematic
```

## Core Syntax / API Reference

### Netlist grammar
Each line: `Name Nplus Nminus [value/spec] [; drawing-hints]`
```python
cct = Circuit("""
V1 1 0 {5*u(t)}   ; down        # step source, drawn downward
R1 1 2 R          ; right=2      # symbolic R, 2 units to the right
C1 2 0 C          ; down         # symbolic C
W  2 3            ; right        # wire
""")
```
- **Sources**: `V 1 0 dc 5`, `V 1 0 ac 1`, `V 1 0 step 5`, `V 1 0 {expr}`,
  `I ...` for current; symbolic if you pass a name (`V 1 0 V`).
- **Passives**: `R`, `C`, `L` with numeric or symbolic values.
- **Wire**: `W n1 n2`; **open**: `O`; controlled sources `E`,`G`,`F`,`H`.
- **Drawing hints** after `;`: `right`, `left`, `up`, `down`, `right=2`, `rotate`.

### Domains & variables
```python
from lcapy import s, t, f, omega, jw
H(s)          # Laplace domain
H(t)          # time domain (inverse Laplace)
H(f)          # Fourier / frequency (Hz)
H(jw)         # angular frequency
```
Expressions are SymPy-backed; `.simplify()`, `.expand()`, `.latex()` all work.

### Network (one-port) objects
Compose impedances algebraically without a netlist:
```python
from lcapy import R, C, L
net = R(10) + (C(100e-9) | R('R2'))    # series/parallel with | operator
net.Z                                   # impedance Z(s)
net.Y                                   # admittance
net.transfer                            # if a two-port
net.draw('net.svg')
```
`+` = series, `|` = parallel.

### Querying a solved circuit
```python
cct.R1.I          # current through R1 (symbolic)
cct[2].V          # node-2 voltage
cct.R1.V(t)       # time-domain voltage across R1
cct.C1.v          # transient response expression
```

### Transfer functions, poles, zeros
```python
H = cct.transfer(1, 0, 2, 0)
H.poles()             # list of poles
H.zeros()             # list of zeros
H.dc_gain             # DC gain
H.canonical()         # canonical rational form
H.latex()             # LaTeX string of the expression
```

## Analysis / Output Types
- **Symbolic transfer functions** `H(s)`, impedances `Z(s)`, admittances.
- **Time / Laplace / frequency** conversions of any quantity.
- **Bode & pole-zero plots** via Matplotlib.
- **Schematic drawings** via CircuiTikZ (SVG/PNG/PDF/TikZ).
- **Discrete-time** (z-domain) via `lcapy.discretetime`.

## How-To (worked recipes)

### How to style the schematic drawing (the "add color"/style recipe)
`draw()` passes options through to CircuiTikZ; pick symbol style and labeling,
and emit TikZ to color it in LaTeX:
```python
cct.draw('rc.svg',
         style='american',          # 'american' | 'european' | 'british'
         label_values=True,
         label_ids=True,
         draw_nodes='connections',  # 'all' | 'connections' | 'none'
         label_nodes='primary',
         scale=1.2)
# For full color control, emit TikZ and add \ctikzset color in a LaTeX wrapper:
cct.draw('rc.tex')
```

### How to get a symbolic transfer function and its Bode plot
```python
from lcapy import Circuit
cct = Circuit("""
V 1 0 ac 1
R 1 2 R
C 2 0 C
""")
H = cct.transfer(1, 0, 2, 0)
print(H.canonical())               # 1 / (1 + s R C)
H.bode_plot((1, 1e6))              # magnitude+phase vs frequency
```

### How to compute a step response in the time domain
```python
cct = Circuit("""
V 1 0 step 5
R 1 2 1000
C 2 0 1e-6
""")
vout = cct[2].V(t)                 # symbolic v_out(t)
print(vout)                        # 5 - 5*exp(-t/(R C)) form
cct[2].V(t).plot((0, 5e-3))        # plot the transient
```

### How to build an impedance from network primitives
```python
from lcapy import R, C, L
Z = (R('R1') + L('L1')) | C('C1')  # parallel of (R+L) and C
print(Z.Z(s).canonical())
print(Z.Z(jw))                     # frequency-domain impedance
```

### How to render a pole-zero map
```python
H = cct.transfer(1, 0, 2, 0)
H.pole_zero_plot()
```

## Do's and Don'ts

### ✅ Do
- Use symbolic component names (`R`, `C`, `R1`) when you want formulas, numeric
  values when you want numbers.
- Pick the domain explicitly: `H(s)`, `H(t)`, `H(f)`, `H(jw)`.
- Add `; right`/`; down` drawing hints so schematics lay out sensibly.
- Use `.canonical()`/`.simplify()` to tame large symbolic expressions.
- Keep circuits **linear** — Lcapy assumes LTI.

### ❌ Don't
- Don't include nonlinear devices (diodes as rectifiers, transistors in large
  signal) — Lcapy is linear-only; linearize first.
- Don't expect drawing without a LaTeX/CircuiTikZ toolchain installed.
- Don't confuse `|` (parallel) with Python bitwise semantics elsewhere — it is
  overloaded only on Lcapy network objects.
- Don't leave nodes unconnected; every node needs a return path.
- Don't let symbolic expressions explode — substitute numbers early when the
  closed form isn't needed.

## Styling, Theming & Customization
- **Schematic**: `style=` (american/european/british), `draw_nodes`,
  `label_nodes`, `label_values`, `label_ids`, `cpt_size`, `node_spacing`,
  `scale`; export `.tex` for full CircuiTikZ color control.
- **Plots**: Bode/pole-zero use Matplotlib; restyle via Matplotlib rcParams.
- **LaTeX output**: `.latex()` on any expression for typeset formulas.

## Advanced Features
- **Two-port networks** (Z/Y/H/ABCD parameters) and their interconnection.
- **Noise analysis** with symbolic spectral densities.
- **Discrete-time / z-domain** signal & filter analysis.
- **Component tolerance / substitution** via `.subs({R: 1e3, C: 1e-6})`.
- **State-space** extraction for linear circuits.
- **SymPy interop** — every quantity is a manipulable symbolic expression.

## Common Pitfalls & Troubleshooting
- **Drawing fails / blank** → LaTeX or CircuiTikZ not installed, or no PDF→image
  converter; install `texlive-pictures` + `pdf2svg`.
- **Huge unreadable expression** → call `.canonical()`/`.simplify()` or
  substitute numeric values.
- **Wrong response** → source type mismatch (`dc`/`ac`/`step`/`{expr}`) for the
  analysis you ran.
- **Nonlinear results nonsensical** → the circuit isn't LTI; Lcapy can't model it.
- **Slow symbolic solve** → reduce symbolic unknowns; numeric-substitute stable
  values.

## Integration Notes
- Great in Jupyter/Livebook-style notebooks — expressions render as LaTeX,
  plots inline.
- Emits CircuiTikZ/TikZ, so schematics can drop straight into LaTeX documents.
- Complements PySpice: Lcapy for the closed form, PySpice for numeric SPICE runs.

## Best For / Avoid For
`symbolic-analysis`, `transfer-functions`, `laplace`, `filter-design`,
`teaching` — choose Lcapy when you need the algebraic result and a matching
schematic. Avoid for nonlinear/large-signal simulation (use PySpice/ngspice) and
for PCB work (use KiCad).

## See Also
- [pyspice.md](pyspice.md) — numeric SPICE simulation in Python
- [spice-netlist.md](spice-netlist.md) — the SPICE netlist format
- [circuitikz.md](circuitikz.md) — the LaTeX drawing backend Lcapy uses
- [schemdraw.md](schemdraw.md) — alternative code-drawn schematics
- ../use-case/engineering-diagrams.md
