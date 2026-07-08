# Lcapy

## What
Lcapy is a Python package for linear circuit analysis and visualization, performing symbolic circuit analysis on top of SymPy. It runs in a Python runtime and produces both symbolic results (transfer functions, LaTeX equations) and circuit drawings, so its consumers are Python scripts/notebooks and matplotlib/LaTeX output.

## How
- **LLM emits:** Python code that constructs a `Circuit(...)` from an inline SPICE-like netlist string (e.g. `V 1 0 dc 5`, `R 1 2 10k`, `C 2 0 100n`).
- **Render path:** call analysis methods such as `cct.transfer(1, 0, 2, 0)` to obtain symbolic transfer functions, and `cct.draw()` to render the schematic. Install with `pip install lcapy` (add `[plotting]` plus sympy/matplotlib/numpy for drawing).
- **Typical final artifact:** LaTeX equations or matplotlib figures (schematic/plots).

## Why
- **Reach for it when:** you want symbolic AC/DC/transient analysis and derived transfer functions alongside a schematic — ideal for teaching and analytically-driven design where the equations matter as much as the drawing.
- **Limitations:** linear circuits only, no nonlinear components, a limited component-model set, and symbolic complexity that grows quickly with circuit size.
- **Relative to siblings:** Lcapy is the symbolic/analytic counterpart to PySpice's numeric SPICE simulation — reach for Lcapy for closed-form transfer functions, PySpice when you need a full numeric simulator's behavior.

## Source
- Solution reference: `fim/solution/lcapy.md`
