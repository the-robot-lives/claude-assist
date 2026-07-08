# SageMath — open-source mathematics system (Python-based CAS)

SageMath is a comprehensive computer algebra system built on Python that unifies ~100 open-source math packages (Maxima, GAP, PARI/GP, Singular, NumPy, matplotlib, R) under one Python-like language. It evaluates symbolic and exact arithmetic, does calculus, number theory, linear algebra, group theory, and cryptography, and renders 2D/3D plots to PNG/SVG/HTML. It runs in a Jupyter notebook, the `sage` REPL, or as a script (`sage script.sage`). For npl-fim, SageMath output is authored as a `.sage` script or notebook cell whose final expressions produce a value or a `Graphics`/`Graphics3d` object.

**Current Version**: SageMath 10.x (current major)  **License**: GPLv3  **Runtime**: CPython 3.11+ interpreter with a preparser; `.sage` files are transpiled to `.py` before running

## Official Resources & Documentation
- Official site: https://www.sagemath.org/
- Reference manual: https://doc.sagemath.org/html/en/reference/
- Tutorial: https://doc.sagemath.org/html/en/tutorial/
- GitHub: https://github.com/sagemath/sage
- Live online (no install): https://sagecell.sagemath.org/  and CoCalc: https://cocalc.com/
- Plotting reference: https://doc.sagemath.org/html/en/reference/plotting/

## Installation & Setup

### Package manager / prebuilt
```bash
# conda-forge (recommended cross-platform)
mamba create -n sage sage python=3.11
conda activate sage

# Debian/Ubuntu
apt-get install sagemath

# macOS
brew install --cask sage
```

### Docker
```bash
docker run -it -p 8888:8888 sagemath/sagemath:latest sage-jupyter
```

### Running code
```bash
sage                      # interactive REPL
sage script.sage          # run a Sage script (preparser applied)
sage -n jupyter           # launch Jupyter with the Sage kernel
sage -python script.py    # run plain Python against Sage's interpreter
```

### The preparser (critical to understand)
`.sage` files are NOT plain Python. Sage's preparser rewrites source before execution:
- `^` means exponentiation (not XOR). Use `^^` for XOR.
- Integer literals become Sage `Integer` objects (`2/3` is the exact rational `2/3`, not `0.666...`).
- `R.<x> = QQ[]` generator-injection syntax is Sage-only.
- `[1..10]` is an inclusive range list.

When writing plain `.py` for the Sage interpreter, none of this applies — use `Integer`, `**`, and `srange`/`range` explicitly.

## Core Syntax / API Reference

### Symbolic expressions & calculus
```python
var('x y z')                       # declare symbolic variables
f = x^2 + 3*x - 5
diff(f, x)                         # 2*x + 3
integral(f, x)                     # 1/3*x^3 + 3/2*x^2 - 5*x
integral(exp(-x^2), x, -oo, oo)    # sqrt(pi)   (definite)
limit(sin(x)/x, x=0)               # 1
taylor(sin(x), x, 0, 7)            # series expansion to order 7
f.subs(x=2)                        # substitute
(x^2 - 1).factor()                 # (x - 1)*(x + 1)
expand((x + y)^3)
```

### Solving
```python
solve(x^2 - 4 == 0, x)                 # [x == -2, x == 2]
solve([x + y == 5, x - y == 1], x, y)  # [[x == 3, y == 2]]
find_root(cos(x) - x, 0, 1)            # numeric root in [0,1]

# ODEs
t = var('t'); y = function('y')(t)
desolve(diff(y, t) + y == 0, y)        # symbolic ODE solve
```

### Exact number systems (parents)
```python
ZZ    # integers        QQ  # rationals
RR    # 53-bit reals    CC  # complex
RDF   # machine double  QQbar # algebraic closure
GF(7) # finite field    Zmod(12) # integers mod 12
2/3 + 1/6                # 5/6  (exact)
sqrt(2)                  # stays symbolic; sqrt(2).n(50) for 50-digit numeric
```

### Number theory
```python
is_prime(17)            # True
next_prime(100)         # 101
factor(120)             # 2^3 * 3 * 5
gcd(48, 36); lcm(4, 6)
euler_phi(36)           # 12
mod(17, 5)              # 2
inverse_mod(3, 7)       # 5
continued_fraction(pi)  # [3; 7, 15, 1, 292, ...]
```

### Linear algebra
```python
A = matrix(QQ, [[1, 2], [3, 4]])
A.det()                 # -2
A.inverse()
A.eigenvalues()         # exact/algebraic eigenvalues
A.rref()                # reduced row echelon
A.characteristic_polynomial()
v = vector([1, 2, 3]); w = vector([4, 5, 6])
v.cross_product(w)      # (-3, 6, -3)
v.dot_product(w)        # 32
```

### Polynomials & rings
```python
R.<x> = QQ[]            # univariate polynomial ring over QQ
p = x^3 - 2*x + 1
p.roots(AA)            # roots over the real algebraic field
p.factor()
S.<a,b> = GF(5)[]      # multivariate over GF(5)
```

### Group theory
```python
G = SymmetricGroup(4)
G.order()               # 24
G.is_abelian()          # False
p = G("(1,2,3)"); q = G("(2,3,4)")
p * q                   # composed permutation
D = DihedralGroup(6); D.cayley_table()
```

## Plotting / Output Types

SageMath produces `Graphics` (2D) and `Graphics3d` (3D) objects. In a notebook they auto-display; from a script call `.save()`.

```python
# 2D
p = plot(sin(x), (x, -2*pi, 2*pi), color='blue', thickness=2)
p += plot(cos(x), (x, -2*pi, 2*pi), color='red', linestyle='--')
p.save('trig.png', figsize=[8, 4], dpi=150)
p.save('trig.svg')                        # vector output

parametric_plot((cos(t), sin(t)), (t, 0, 2*pi))
polar_plot(1 + cos(x), (x, 0, 2*pi))
list_plot([(1,1), (2,4), (3,9)], plotjoined=True)
contour_plot(x^2 - y^2, (x, -2, 2), (y, -2, 2))

# 3D
var('u v')
plot3d(sin(x*y), (x, -2, 2), (y, -2, 2))
parametric_plot3d((cos(u)*sin(v), sin(u)*sin(v), cos(v)),
                  (u, 0, 2*pi), (v, 0, pi))
implicit_plot3d(x^2 + y^2 + z^2 == 1, (x,-1,1), (y,-1,1), (z,-1,1))
```

Concrete output kinds: `plot`, `parametric_plot`, `polar_plot`, `list_plot`, `bar_chart`, `histogram`, `contour_plot`, `density_plot`, `vector_field` (`plot_vector_field`), `region_plot`, `matrix_plot`, `graphics_array` (grids), and 3D: `plot3d`, `parametric_plot3d`, `implicit_plot3d`, `list_plot3d`, `revolution_plot3d`.

## How-To

### How to add colors, styles & a legend to a 2D plot
```python
var('x')
g  = plot(x^2,   (x, -3, 3), color='#1f77b4', thickness=2.5, legend_label=r'$x^2$')
g += plot(x^3/4, (x, -3, 3), color='#d62728', linestyle='--',
          legend_label=r'$x^3/4$', fill='axis', fillcolor='#d62728', fillalpha=0.1)
g.set_legend_options(loc='upper left', font_size=12)
g.axes_labels(['$x$', '$y$'])
g.save('styled.svg', gridlines=True, frame=True)
```
Colors accept named strings, `'#rrggbb'` hex, or RGB tuples `(0.1, 0.4, 0.8)`. `fill`, `fillcolor`, `fillalpha`, `gridlines`, and `frame` control the fill/grid theming.

### How to export publication-quality vector output
```python
p = plot(sin(x)/x, (x, -20, 20))
p.save('sinc.svg')                        # SVG for web / vector
p.save('sinc.pdf', figsize=[6, 4])        # PDF for LaTeX inclusion
p.save('sinc.png', dpi=300, transparent=True)
```
Prefer `.svg`/`.pdf` when the target is a document; PNG needs an explicit high `dpi` to avoid rasterization blur.

### How to solve a system and pretty-print the result as LaTeX
```python
var('x y')
sol = solve([x + 2*y == 4, 3*x - y == 5], x, y, solution_dict=True)
print(latex(sol[0][x]), latex(sol[0][y]))   # LaTeX strings for embedding
show(sol)                                    # rendered math in a notebook
```
`latex(obj)` returns a LaTeX string for any Sage object; `show()` renders it via MathJax in Jupyter.

### How to build a 3D surface and rotate/save it
```python
var('x y')
S = plot3d(sin(sqrt(x^2 + y^2)), (x, -8, 8), (y, -8, 8),
           color='auto', mesh=True, opacity=0.9)
S.save('surface.png', viewer='tachyon', figsize=[8, 8])   # ray-traced still
S.save('surface.html')                                     # interactive three.js
```
`.html` embeds an interactive three.js viewer; `viewer='tachyon'` produces a ray-traced raster still.

### How to make a grid of subplots
```python
plots = [plot(x^n, (x, 0, 1), title=f'x^{n}') for n in range(1, 5)]
graphics_array(plots, nrows=2, ncols=2).save('grid.svg')
```

## Do's and Don'ts

### ✅ Do
- Declare every symbol with `var('x y')` before use — undeclared names raise `NameError`.
- Use `^` for powers in `.sage` files/notebooks (the preparser maps it to exponentiation).
- Keep values exact (`QQ`, `ZZ`) as long as possible; call `.n()`/`.numerical_approx()` only at the end for a float.
- Use raw strings for LaTeX labels: `legend_label=r'$\sin x$'`.
- Save vector formats (`.svg`, `.pdf`) for documents; set `dpi=300` when you must rasterize.

### ❌ Don't
- Don't use `^` for XOR in `.sage` — it means power. Use `^^`.
- Don't assume `**` semantics from plain Python inside `.sage`; the preparser also wraps integer literals, so `type(2)` is `Integer`, not `int`.
- Don't call `.show()` in a headless script expecting a file — it opens a viewer; use `.save(path)` instead.
- Don't mix a symbolic `var('x')` and a polynomial-ring generator `R.<x>=QQ[]` with the same name in one scope — they are different objects and silently shadow.
- Don't invent an `npl_to_sage()` helper — there is no such API; author plain Sage and let the value/`Graphics` object be the output.

## Styling, Theming & Customization
- Per-plot options: `color`, `rgbcolor`, `thickness`, `linestyle` (`'-'`, `'--'`, `':'`, `'-.'`), `alpha`, `fill`, `fillcolor`, `fillalpha`, `legend_label`.
- Figure-level (passed to `.save()`/`show()`): `figsize=[w,h]`, `dpi`, `gridlines` (`True`/`'minor'`/`'major'`), `frame`, `axes`, `axes_labels`, `fontsize`, `transparent`, `aspect_ratio`.
- Colormaps for density/contour/3D: `cmap='viridis'` (matplotlib colormaps) — e.g. `density_plot(sin(x*y), (x,-2,2), (y,-2,2), cmap='plasma')`.
- Named colors, hex strings, RGB tuples, and `Color('teal')` objects are all accepted; `hue(0.6)` gives an evenly-spaced palette color.
- `matplotlib` styling: because 2D rendering is matplotlib-backed, `p.matplotlib()` returns a `Figure` you can restyle with rcParams before saving.

## Advanced Features
- Interactive notebook controls: `@interact` decorator generates sliders/dropdowns bound to function arguments.
  ```python
  @interact
  def _(n=(1, 10), c=Color('red')):
      show(plot(x^n, (x, -1, 1), color=c))
  ```
- Symbolic → fast numeric: `fast_callable(expr, vars=[x], domain=float)` compiles an expression for tight loops.
- Interfaces to bundled engines: `maxima_calculus`, `gap`, `pari`, `singular`, `r` for domain-specific power.
- `@parallel` decorator and `@cached_function` for scaling and memoization.
- Cryptography: `elliptic_curves`, `EllipticCurve(GF(p), [a,b])`, RSA/DLP toy tooling in `sage.crypto`.

## Common Pitfalls & Troubleshooting
- **`^` surprises**: in the plain-Python (`sage -python`) interpreter `^` is XOR again — only `.sage`/REPL preparse it. Keep this straight per file type.
- **Exact vs float leakage**: `RR(pi)` vs `pi` behave differently in comparisons; `bool(sqrt(2)^2 == 2)` may need `.simplify_full()` first.
- **Assumptions**: `integrate`/`solve` sometimes need `assume(x > 0)` to return; `forget()` clears assumptions.
- **Headless plotting**: set a non-interactive matplotlib backend or always `.save()`; `.show()` needs a display.
- **Slow symbolic solve**: prefer `find_root`/numeric when an exact closed form is unnecessary.
- **Big 3D `.html`**: interactive exports embed geometry inline and can be multi-MB; use `viewer='tachyon'` PNG for size-sensitive contexts.

## Integration Notes
- Jupyter: use the **SageMath** kernel (not plain Python) so the preparser is active; `show()` renders LaTeX via MathJax.
- LaTeX documents: `latex(obj)` emits embeddable math; `.save('fig.pdf')` gives vector figures for `\includegraphics`.
- SageCell (https://sagecell.sagemath.org) executes a self-contained script and returns the last graphic — good for reproducible npl-fim snippets with zero install.
- For pure symbolic work with no bundled-engine needs, **SymPy** (see `sympy.md`) is lighter weight and pip-installable.

## Best For / Avoid For
`exact-arithmetic`, `number-theory`, `abstract-algebra`, `research-math`, `cryptography`, `notebook-driven` — choose SageMath when you need many math domains, exact/algebraic number systems, or bundled engines (GAP, PARI, Singular).

Avoid for: lightweight symbolic-only tasks embeddable anywhere (use SymPy), production web dashboards (use Dash/Streamlit), or when a ~1GB install is unacceptable.

## See Also
- `sympy.md` — pip-installable pure-Python symbolic math (subset of Sage's symbolic layer)
- `tikz-pgf.md` / `metapost.md` — vector math figures for LaTeX documents
- `ipywidgets.md` — interactive notebook controls (analog of Sage's `@interact`)
- `../use-case/mathematical-notation.md`, `../use-case/scientific-computing.md`
