# SymPy — pure-Python symbolic mathematics

SymPy is a symbolic mathematics (CAS) library written entirely in Python with no external dependencies. It manipulates algebraic expressions exactly, does calculus (derivatives, integrals, limits, series), solves equations and ODEs, works with matrices, and pretty-prints results as Unicode, LaTeX, or ASCII. It runs anywhere Python runs — scripts, Jupyter, or the browser via Pyodide. For npl-fim, SymPy output is authored as a `.py` script or notebook cell whose result is either a printed expression, a LaTeX string (via `sympy.latex(...)`), or a plot (via `sympy.plotting`).

**Current Version**: SymPy 1.13+ (current major)  **License**: BSD-3-Clause  **Runtime**: Pure Python 3.9+; optional `matplotlib` for plotting, `IPython`/`MathJax` for rendered math

## Official Resources & Documentation
- Docs: https://docs.sympy.org/latest/
- Tutorial: https://docs.sympy.org/latest/tutorials/intro-tutorial/index.html
- GitHub: https://github.com/sympy/sympy
- Live shell: https://live.sympy.org/
- Plotting module: https://docs.sympy.org/latest/modules/plotting.html

## Installation & Setup

### pip / conda
```bash
pip install sympy
pip install matplotlib          # required for sympy.plotting
conda install -c conda-forge sympy
```

### Import styles
```python
# Explicit (recommended for scripts — no namespace surprises)
import sympy as sp
x = sp.Symbol('x')

# Star import (convenient in notebooks/REPL)
from sympy import symbols, diff, integrate, solve, Eq, sin, cos, exp, oo, pi

# Pretty printing in notebooks
from sympy import init_printing
init_printing()                 # Unicode/MathJax output
```

## Core Syntax / API Reference

### Symbols & assumptions
```python
from sympy import symbols
x, y, z = symbols('x y z')                    # generic complex symbols
a, b     = symbols('a b', real=True)          # assume real
n        = symbols('n', integer=True, positive=True)
f, g     = symbols('f g', cls=sp.Function)    # undefined functions
```
Assumptions (`real`, `positive`, `integer`, `nonzero`, `commutative`, ...) change what `simplify`/`solve`/`integrate` are allowed to do. They are queried with `x.is_positive`, etc.

### Building & manipulating expressions
```python
expr   = x**2 + 2*x + 1
factor(expr)               # (x + 1)**2
expand((x + y)**3)         # x**3 + 3*x**2*y + 3*x*y**2 + y**3
simplify(sin(x)**2 + cos(x)**2)   # 1
expr.subs(x, 2)            # 9
expr.subs({x: y + 1})      # substitute an expression
together(1/x + 1/y)        # (x + y)/(x*y)
apart(1/(x*(x+1)))         # 1/x - 1/(x + 1)
collect(x*a + x*b + y, x)  # x*(a + b) + y
```
Key idiom: SymPy expressions are **immutable** — every operation returns a new object. `Eq(lhs, rhs)` represents an equation; a bare `x**2 - 4` passed to `solve` is treated as `... == 0`.

### Calculus
```python
diff(sin(x)*exp(x), x)            # exp(x)*sin(x) + exp(x)*cos(x)
diff(f(x, y), x, 2, y)           # mixed higher-order partial
integrate(x**2 * cos(x), x)      # indefinite
integrate(exp(-x**2), (x, -oo, oo))   # sqrt(pi)  (definite)
limit(sin(x)/x, x, 0)            # 1
limit(1/x, x, 0, '+')            # oo  (one-sided)
exp(x).series(x, 0, 5)           # 1 + x + x**2/2 + x**3/6 + x**4/24 + O(x**5)
summation(1/n**2, (n, 1, oo))    # pi**2/6
```

### Solving
```python
solve(x**2 - 4, x)                       # [-2, 2]
solve([Eq(x + y, 5), Eq(x - y, 1)], [x, y])   # {x: 3, y: 2}
solveset(sin(x), x, domain=sp.S.Reals)   # {2*n*pi} ∪ {2*n*pi + pi}  (set form)
nsolve(cos(x) - x, x, 0.5)               # numeric root near 0.5

# ODEs
f = sp.Function('f')
dsolve(Eq(f(x).diff(x, 2) - f(x), 0), f(x))   # f(x) = C1*exp(-x) + C2*exp(x)
```
Prefer `solveset` for complete solution sets over the older `solve` when the domain matters; use `nsolve` when no closed form exists.

### Matrices & linear algebra
```python
from sympy import Matrix
M = Matrix([[1, 2], [3, 4]])
M.det()            # -2
M.inv()            # Matrix([[-2, 1], [3/2, -1/2]])
M.eigenvals()      # {5/2 - sqrt(33)/2: 1, 5/2 + sqrt(33)/2: 1}
M.eigenvects()
M.rref()           # reduced row echelon (rref matrix, pivot cols)
M.nullspace(); M.columnspace()
Matrix([[1,2],[3,4]]) @ Matrix([[5],[6]])     # matmul
```

### Numeric evaluation & lambdify
```python
sp.pi.evalf(50)                  # 50-digit pi
expr.evalf(subs={x: 2})          # numeric value
import numpy as np
fn = sp.lambdify(x, sin(x)/x, 'numpy')   # compile to a NumPy-vectorized function
fn(np.linspace(-10, 10, 200))
```
`lambdify` is the bridge to fast numeric arrays — never loop `.evalf()` over data.

## Output / Rendering Types
```python
sp.pprint(sp.Integral(x**2, x))     # Unicode pretty-print to terminal
print(sp.latex(sp.Integral(x**2, x)))   # \int x^{2}\, dx   (embed in docs)
print(sp.ccode(x**2 + 1))           # C:      pow(x, 2) + 1
print(sp.pycode(x**2 + 1))          # Python: x**2 + 1
print(sp.mathematica_code(expr)); print(sp.octave_code(expr))
sp.srepr(expr)                      # exact internal tree (round-trippable)
```
Concrete printable/exportable targets: Unicode pretty, LaTeX, MathML, ASCII, C, Fortran, Python, Octave/Matlab, Julia, Rust, JavaScript, and Mathematica code generation.

## Plotting (sympy.plotting)
```python
from sympy import plot, symbols, sin, cos
from sympy.plotting import plot3d, plot_parametric, plot3d_parametric_surface
x, y = symbols('x y')

p = plot(sin(x), cos(x), (x, -2*sp.pi, 2*sp.pi), show=False,
         xlabel='x', ylabel='y', legend=True)
p[0].line_color = 'blue'
p[1].line_color = 'red'
p.save('trig.svg')                 # matplotlib backend -> svg/png/pdf

plot_parametric((cos(x), sin(x)), (x, 0, 2*sp.pi))
plot3d(sin(sp.sqrt(x**2 + y**2)), (x, -5, 5), (y, -5, 5))
plot3d_parametric_surface(cos(x)*sin(y), sin(x)*sin(y), cos(y),
                          (x, 0, 2*sp.pi), (y, 0, sp.pi))
```
`sympy.plotting` wraps matplotlib. Pass `show=False` to get a `Plot` object you can restyle and `.save()`.

## How-To

### How to add colors, labels & a legend to a SymPy plot
```python
from sympy import plot, symbols, sin, cos, pi
x = symbols('x')
p = plot(sin(x), cos(x), (x, -2*pi, 2*pi),
         show=False, legend=True, title='Trig',
         xlabel='$x$', ylabel='$y$', axis_center=(0, 0))
p[0].line_color = '#1f77b4'; p[0].label = r'$\sin x$'
p[1].line_color = '#d62728'; p[1].label = r'$\cos x$'
p.save('styled.svg')
```
Each series is a `p[i]` object with `line_color`, `label`, and (for surfaces) `surface_color`. For finer control, drop to matplotlib via `p._backend.fig` after `p.show()`, or `lambdify` + plot manually.

### How to emit a LaTeX string for embedding in a document
```python
import sympy as sp
x = sp.Symbol('x')
result = sp.integrate(sp.exp(-x**2), (x, -sp.oo, sp.oo))
print(sp.latex(sp.Eq(sp.Integral(sp.exp(-x**2), (x, -sp.oo, sp.oo)), result)))
# \int\limits_{-\infty}^{\infty} e^{- x^{2}}\, dx = \sqrt{\pi}
```
`sp.latex()` is the canonical way to move SymPy results into TikZ/LaTeX/Markdown-math.

### How to solve then verify a result
```python
import sympy as sp
x = sp.Symbol('x')
sols = sp.solve(x**3 - 6*x**2 + 11*x - 6, x)   # [1, 2, 3]
assert all(sp.expand((x**3 - 6*x**2 + 11*x - 6).subs(x, s)) == 0 for s in sols)
```
Always back-substitute with `.subs()` to confirm — `solve` can return spurious or missing branches under wrong assumptions.

### How to turn a symbolic expression into a fast NumPy function
```python
import sympy as sp, numpy as np
x = sp.Symbol('x')
expr = sp.sin(x) / x
f = sp.lambdify(x, expr, modules=['numpy'])
xs = np.linspace(-20, 20, 400)
ys = f(xs)                      # vectorized, no Python-level loop
```

### How to compute a Taylor series and overlay it on the exact function
```python
import sympy as sp
x = sp.Symbol('x')
f = sp.sin(x)
approx = f.series(x, 0, 8).removeO()          # 8th-order Taylor, drop the O() term
print(sp.latex(approx))                        # embeddable LaTeX of the polynomial
p = sp.plot(f, approx, (x, -sp.pi, sp.pi), show=False, legend=True)
p[0].line_color = 'black'; p[0].label = r'$\sin x$'
p[1].line_color = 'red';   p[1].label = 'Taylor (deg 7)'
p.save('taylor.svg')
```
`.series(x, x0, n)` returns an expansion with a trailing `O(x**n)`; call `.removeO()` to get a plain polynomial you can plot, `lambdify`, or convert to LaTeX.

### How to work with units and dimensional analysis
```python
from sympy.physics.units import meter, second, kilogram, convert_to
from sympy.physics.units import speed_of_light
distance = 100 * meter
time = 9.58 * second
speed = distance / time
convert_to(speed, meter/second)               # 10.4384... m/s
convert_to(speed_of_light, meter/second)      # 299792458 m/s
```
`sympy.physics.units` carries dimensions through arithmetic; `convert_to(expr, target_units)` rescales and catches dimensional mismatches.

## Do's and Don'ts

### ✅ Do
- Declare symbols with assumptions when they matter (`positive=True`, `real=True`) so `simplify`/`integrate` can close.
- Use `Eq(a, b)` for equations; pass bare expressions to `solve` only when you mean `expr == 0`.
- Use `sp.Rational(1, 3)` or `sp.Integer(2)/3` for exact fractions — `1/3` in Python is a float `0.333...`.
- Use `lambdify` to evaluate over arrays; call `.evalf()` only for single points.
- Prefer `solveset`/`linsolve`/`nonlinsolve` for complete, domain-aware solution sets.

### ❌ Don't
- Don't write `1/3` expecting a symbolic rational — Python evaluates it to a float before SymPy sees it. Use `sp.S(1)/3` or `Rational(1,3)`.
- Don't mutate expressions in place — they're immutable; capture the return value.
- Don't compare expressions with `==` for mathematical equality; `==` is structural. Use `sp.simplify(a - b) == 0` or `a.equals(b)`.
- Don't loop `.evalf()` over thousands of points — `lambdify` first.
- Don't invent a `parse_math()`/`npl_fim` bridge — SymPy has no such module; use `sympify("x**2 + 1")` to parse strings and let the expression/LaTeX be the output.

## Styling, Theming & Customization
- Printing: `init_printing(use_unicode=True)` in terminals, or `init_printing()` in Jupyter for MathJax. `use_latex='mathjax'` forces LaTeX rendering.
- Plot styling: per-series `line_color`, `surface_color`, `label`; plot-level `title`, `xlabel`, `ylabel`, `legend`, `axis_center`, `xscale='log'`, `size=(w, h)`.
- Colors accept matplotlib names, hex (`'#1f77b4'`), or a callable `line_color=lambda a: a` for gradient coloring along the parameter.
- Backend: SymPy plotting is matplotlib; set matplotlib rcParams / styles (`plt.style.use('seaborn-v0_8')`) before rendering for global theming.
- LaTeX output styling: `sp.latex(expr, mode='equation')`, `mul_symbol='dot'`, `order='lex'` tune the emitted string.

## Advanced Features
- Assumptions engine & `refine(expr, Q.positive(x))` for context-aware simplification.
- Code generation: `sympy.codegen`, `autowrap`, and `lambdify(..., 'numpy'/'math'/'mpmath')` targets.
- Arbitrary precision via `mpmath` backend: `sp.N(sp.pi, 100)`.
- `sympify()` / `parse_expr()` parse strings into expressions (use `evaluate=False` to preserve structure).
- Physics & specialized modules: `sympy.physics.mechanics`, `sympy.stats`, `sympy.geometry`, `sympy.combinatorics`.
- Units: `sympy.physics.units` for dimensional analysis.

## Common Pitfalls & Troubleshooting
- **Float contamination**: any Python-native `1/2`, `2.0`, or NumPy value entering an expression drops it to floats. Wrap literals with `sp.S(...)`/`Rational`.
- **`==` is not equality**: `sin(x)**2 + cos(x)**2 == 1` is `False` (structural). Simplify the difference instead.
- **Unevaluated integrals**: `integrate` returns an `Integral` object when it can't solve — add assumptions or try `manualintegrate`/`risch`.
- **Slow `solve`**: for polynomials use `roots`/`real_roots`; for linear systems use `linsolve`; fall back to `nsolve` for numeric.
- **Plot needs matplotlib**: `sympy.plotting` raises if matplotlib isn't installed.
- **Symbol name vs Python variable**: `x = Symbol('t')` makes the printed name `t`; keep them aligned to avoid confusion in output.

## Integration Notes
- Jupyter/IPython: `init_printing()` gives MathJax-rendered results inline.
- LaTeX/Markdown docs: pipe `sp.latex(expr)` into `$$...$$` blocks.
- NumPy/SciPy pipelines: `lambdify` bridges symbolic derivation → numeric compute.
- When you need bundled algebra engines, finite fields at scale, or number-theory depth, step up to **SageMath** (see `sagemath.md`), which embeds SymPy-like symbolic plus much more.

## Best For / Avoid For
`symbolic-math`, `calculus`, `equation-solving`, `latex-generation`, `code-generation`, `portable` — choose SymPy when you need dependency-free symbolic manipulation, LaTeX output, or symbolic→numeric codegen embeddable in any Python environment.

Avoid for: heavy numeric linear algebra on large matrices (use NumPy/SciPy), abstract-algebra/number-theory research at scale (use SageMath), or interactive dashboards (Dash/Streamlit).

## See Also
- `sagemath.md` — full CAS superset with bundled engines and exact number systems
- `tikz-pgf.md` — render SymPy `latex()` output as typeset math/figures
- `matplotlib.md` — the plotting backend SymPy wraps
- `../use-case/mathematical-notation.md`, `../use-case/scientific-computing.md`
