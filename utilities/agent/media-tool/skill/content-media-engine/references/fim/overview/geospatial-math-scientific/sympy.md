# SymPy

## What
SymPy is a pure-Python library for symbolic mathematics — algebra, calculus, equation solving, and matrix operations — with LaTeX output support. Its primary consumer is a Python runtime (script or notebook); it installs with a simple `pip install sympy`.

## How
- The LLM emits **Python/SymPy code** — declare symbols (`x, y = symbols('x y')`), then build expressions and call `factor`/`expand`/`subs`, calculus (`diff`, `integrate`, `limit`, `.series(...)`), `solve([...], [...])`, `dsolve(...)`, and `Matrix(...)` methods (`det`, `inv`, `eigenvals`).
- That runs in Python; results are exact symbolic objects, optionally rendered to LaTeX (via IPython) or plotted with matplotlib.
- Typical final artifact: **symbolic results** (simplified expressions, solutions, LaTeX strings), optionally displayed inline in a notebook.

## Why
- Reach for SymPy when you need lightweight, pip-installable symbolic math inside an ordinary Python project — differentiation, integration, solving, series, and matrix algebra — without a heavyweight system.
- Main tradeoff: as a pure-Python library it is slower on large computations and covers less breadth than a full CAS distribution.
- Relative to its siblings: SymPy is the minimal symbolic library that `sagemath` builds upon and integrates; choose Sage when you need number theory, group theory, or an all-in-one environment, SymPy when you just need symbolic math in plain Python.

## Source
- Solution reference: `fim/solution/sympy.md`
