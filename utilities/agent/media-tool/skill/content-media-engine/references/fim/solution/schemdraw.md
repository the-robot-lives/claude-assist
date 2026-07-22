# SchemDraw — Programmatic Circuit Schematics in Python

SchemDraw draws electrical schematics, logic diagrams, signal-processing block
diagrams, and flowcharts from Python code. You append elements to a `Drawing`;
each element flows from where the last one ended, with fluent direction and
label methods. It renders through a Matplotlib **or** a pure-SVG backend, making
it ideal for generating figures in scripts, notebooks, and docs.

**Current Version**: schemdraw 0.19+ (current)  **License**: MIT
**Runtime**: Python 3.8+; Matplotlib or built-in SVG backend

## Official Resources & Documentation
- Docs: https://schemdraw.readthedocs.io/
- Element gallery: https://schemdraw.readthedocs.io/en/latest/elements/elements.html
- GitHub: https://github.com/cdelker/schemdraw
- PyPI: https://pypi.org/project/schemdraw/
- Examples: https://schemdraw.readthedocs.io/en/latest/examples/index.html

## Installation & Setup

### pip
```bash
pip install schemdraw               # SVG backend included
pip install "schemdraw[matplotlib]" # add Matplotlib backend
```

### Choose a backend
```python
import schemdraw
schemdraw.use('svg')          # pure SVG (no Matplotlib dependency)
# schemdraw.use('matplotlib') # default when installed
```

### Minimal drawing
```python
import schemdraw
import schemdraw.elements as elm

with schemdraw.Drawing() as d:
    d += elm.Resistor().label('1kΩ')
    d += elm.Capacitor().down().label('100nF')
    d += elm.Ground()
d.save('rc.svg')
```

## Core Syntax / API Reference

### Drawing lifecycle
```python
with schemdraw.Drawing() as d:      # auto-renders on exit
    d += elm.Resistor()
# or explicit:
d = schemdraw.Drawing()
d += elm.Resistor()
d.draw()                            # render (returns SVG/inline in notebooks)
d.save('out.svg')                   # svg | png | pdf | jpg
```
`d += element` is shorthand for `d.add(element)`; both return the placed element
so you can capture its anchors.

### Direction & placement (fluent)
```python
elm.Resistor().right()      # default
elm.Resistor().up()
elm.Resistor().down()
elm.Resistor().left()
elm.Resistor().theta(30)    # arbitrary angle
elm.Resistor().length(3)    # segment length in units
```
Absolute / relative positioning:
```python
elm.Resistor().at((0, 0))       # start at a coordinate
elm.Line().to((3, -2))          # end at a coordinate
elm.Line().tox(4)               # end at x=4, keep y
elm.Line().toy(-2)              # end at y=-2, keep x
```

### Saving and restoring position
```python
with schemdraw.Drawing() as d:
    d += elm.Resistor().label('R1')
    d.push()                       # remember current point
    d += elm.Capacitor().down()
    d.pop()                        # return to remembered point
    d += elm.Inductor().right()
```

### Labels
```python
elm.Resistor().label('R1')                       # default (top of horizontal)
elm.Resistor().label('R1', loc='bottom')         # loc: top|bottom|left|right
elm.Capacitor().label(['+', 'C1', '−'], loc='top')  # multiple labels
elm.SourceV().label('$V_{cc}$')                  # LaTeX-ish math
elm.Resistor().label('R1', ofst=0.3, rotate=True)
```

### Anchors (named connection points)
```python
with schemdraw.Drawing() as d:
    op = d.add(elm.Opamp())
    d += elm.Line().left().at(op.in1)
    d += elm.Line().left().at(op.in2)
    d += elm.Line().right().at(op.out)

    q = d.add(elm.BjtNpn())
    d += elm.Line().at(q.base).left()
    d += elm.Line().at(q.collector).up()
    d += elm.Line().at(q.emitter).down()
```
Two-terminal elements expose `.start`, `.end`, `.center`; multi-terminal
elements expose named anchors (`in1`, `in2`, `out`, `base`, `collector`, …).

### Element styling
```python
elm.Resistor().color('blue')
elm.Resistor().fill('#ffcc00')
elm.Resistor().linewidth(2).linestyle('--')
elm.Diode().color('red').label('D1')
```

## Element Catalog (`elm.*`, `logic.*`, `dsp.*`, `flow.*`)
- **Passives**: `Resistor`, `ResistorIEC`, `Capacitor`, `Capacitor2`,
  `Inductor`, `Inductor2`, `Potentiometer`, `Fuse`, `Crystal`.
- **Sources**: `SourceV`, `SourceI`, `SourceSin`, `Battery`, `BatteryCell`.
- **Semiconductors**: `Diode`, `LED`, `Zener`, `Schottky`, `Bjt`, `BjtNpn`,
  `BjtPnp`, `NFet`, `PFet`, `NMos`, `PMos`, `Opamp`.
- **Connectors/lines**: `Line`, `Dot`, `Arrow`, `Ground`, `GroundSignal`,
  `Vdd`, `Vss`, `Label`, `Gap`.
- **Switches**: `Switch`, `Button`, `SwitchSpdt`.
- **Logic** (`import schemdraw.logic as logic`): `And`, `Or`, `Not`, `Nand`,
  `Nor`, `Xor`, `Xnor`, `Buf`.
- **DSP** (`import schemdraw.dsp as dsp`): `Amp`, `Mixer`, `Filter`, `Adc`,
  `Dac`, `Sum`, `Circle`, `Square`.
- **Flow** (`import schemdraw.flow as flow`): `Start`, `Box`, `Decision`,
  `Data`, `Connect` for flowcharts.

## How-To (worked recipes)

### How to add colors and styling (the "add color" recipe)
Per-element methods tint stroke/fill; drawing-level config sets defaults:
```python
import schemdraw, schemdraw.elements as elm
with schemdraw.Drawing() as d:
    d.config(lw=1.5, fontsize=14)              # drawing-wide defaults
    d += elm.Resistor().color('teal').label('R1')
    d += elm.Capacitor().color('crimson').fill('#ffe').down()
    d += elm.Ground().color('gray')
```

### How to close a loop back to the start
Capture the start anchor, then route the final element `.to()` it:
```python
with schemdraw.Drawing() as d:
    R = d.add(elm.Resistor().right().label('R'))
    d += elm.Capacitor().down().label('C')
    d += elm.Line().left()
    d += elm.SourceV().up().label('5V').to(R.start)
```

### How to build a labeled op-amp inverting amplifier
```python
with schemdraw.Drawing() as d:
    op = d.add(elm.Opamp(leads=True))
    d += elm.Line().left().at(op.in1).length(1)
    d += elm.Resistor().left().label('$R_{in}$')
    d.push()
    d += elm.Resistor().up().label('$R_f$').at(op.in1)
    d += elm.Line().right().tox(op.out)
    d += elm.Line().down().toy(op.out)
    d.pop()
    d += elm.Line().right().at(op.out).label('$V_{out}$', loc='right')
```

### How to draw a logic gate network
```python
import schemdraw, schemdraw.logic as logic
with schemdraw.Drawing() as d:
    g1 = d.add(logic.And().label('AND'))
    g2 = d.add(logic.Or().right().at((5, -1)))
    d += logic.Line().at(g1.out).to(g2.in1)
```

### How to export to SVG/PNG without a display
```python
import schemdraw
schemdraw.use('svg')
with schemdraw.Drawing(file='amp.svg') as d:
    import schemdraw.elements as elm
    d += elm.Resistor().label('R1')
# 'amp.svg' is written on context exit
```

## Do's and Don'ts

### ✅ Do
- Let elements flow from the previous endpoint; only use `.at()` when you must
  jump.
- Use `d.push()` / `d.pop()` to branch and return instead of recomputing coords.
- Capture placed elements (`R = d.add(...)`) to reach their anchors later.
- Use `schemdraw.use('svg')` in headless/CI environments to avoid Matplotlib.
- Wrap drawings in `with schemdraw.Drawing() as d:` so they auto-render.

### ❌ Don't
- Don't hardcode every coordinate — the flow model exists to avoid that.
- Don't forget `.down()`/`.up()` on branch elements; everything defaults right.
- Don't call `.at()` with a raw tuple when you meant an anchor (or vice versa).
- Don't mix backends mid-script; call `schemdraw.use()` once up front.
- Don't rely on Matplotlib being present in the SVG backend path — install the
  `[matplotlib]` extra only if you actually use it.

## Styling, Theming & Customization
- **Drawing config**: `d.config(unit=2.5, lw=1.2, fontsize=12, color='black')`
  or global `schemdraw.config(...)`.
- **Per-element**: `.color()`, `.fill()`, `.linewidth()`, `.linestyle()`.
- **Fonts/math**: labels accept `$...$` math; font follows the backend.
- **Units**: `unit` sets the default element length; `.length(n)` overrides.
- **Themes**: dark backgrounds via `d.config(bgcolor='#111', color='white')`.

## Advanced Features
- **Custom elements**: subclass `elm.Element` and append `Segment`,
  `SegmentCircle`, `SegmentArc`, `SegmentText` to `self.segments`.
- **Timing diagrams**: `schemdraw.logic.timing` renders WaveJSON-like timing.
- **DSP/flowcharts**: full block-diagram and flowchart element sets.
- **Anchoring math**: combine `.at()`, `.tox()`, `.toy()`, `.to()` for precise
  routing without absolute coordinates.
- **Notebook inline**: returns SVG for Jupyter display automatically.

## Common Pitfalls & Troubleshooting
- **Everything points right** → you forgot direction methods on branches.
- **Anchor is None / AttributeError** → capture the element with `d.add(...)`;
  the `+=` form still returns it, but you must bind it to a variable.
- **Loop doesn't close** → save the start (`R = d.add(...)`) and `.to(R.start)`.
- **Blank output in CI** → switch to the SVG backend (`schemdraw.use('svg')`).
- **Labels overlap symbols** → adjust `loc=` or `ofst=` on `.label()`.

## Integration Notes
- Works headless with the SVG backend — great for docs pipelines and CI.
- In Jupyter/Livebook-style notebooks the drawing renders inline as SVG.
- Emits PNG/PDF via the Matplotlib backend for print-ready figures.

## Best For / Avoid For
`python-schematics`, `notebooks`, `teaching`, `logic-diagrams`, `dsp-blocks` —
choose SchemDraw when you want schematics generated by code with minimal
dependencies. Avoid for PCB layout / manufacturing (use KiCad) and for
symbolic circuit *solving* (use Lcapy, which also draws).

## See Also
- [circuitikz.md](circuitikz.md) — LaTeX-native equivalent for papers
- [lcapy.md](lcapy.md) — schematic drawing plus symbolic analysis
- [kicad.md](kicad.md) — professional capture + PCB
- [pyspice.md](pyspice.md) — simulate the circuits you draw here
- ../use-case/engineering-diagrams.md
