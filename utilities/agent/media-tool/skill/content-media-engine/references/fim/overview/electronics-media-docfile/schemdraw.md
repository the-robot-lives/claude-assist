# SchemDraw

## What
SchemDraw is a pure-Python package for drawing schematic diagrams programmatically, with a matplotlib backend. It runs in a Python runtime and emits circuit schematics via a flow-based drawing API; its consumer is Python code (scripts or notebooks) rendering to image formats.

## How
- **LLM emits:** Python code using a `schemdraw.Drawing()` context and chained `schemdraw.elements` (e.g. `d += elm.Resistor().label('10kΩ')`, `d += elm.Capacitor().down()`), with a flow-based syntax that places components relative to one another.
- **Render path:** run the script; the Drawing renders through matplotlib (or the svgwrite backend). Install with `pip install schemdraw` (extras: `[matplotlib]`, `[svgwrite]`).
- **Typical final artifact:** SVG, PNG, or PDF.

## Why
- **Reach for it when:** you want programmatic, code-generated schematics in a pure-Python environment with an intuitive flow-based layout — good for scripted/generated diagrams and notebook workflows.
- **Limitations:** Python-only, a fairly basic component library, manual layout, and limited automatic routing.
- **Relative to siblings:** SchemDraw is the Python/programmatic analogue to CircuiTikZ's LaTeX approach — choose SchemDraw to generate schematics from code, CircuiTikZ when the schematic must live inside a typeset LaTeX document.

## Source
- Solution reference: `fim/solution/schemdraw.md`
