# SageMath

## What
SageMath is a comprehensive open-source mathematics system covering symbolic math, number theory, linear algebra, group theory, and 2D/3D plotting, wrapping many established math packages behind a Python-based interface. Its primary consumer is the Sage runtime, typically via a Jupyter notebook.

## How
- The LLM emits **Sage/Python code** — `var('x y z')`, then calculus (`derivative`, `integral`, `limit`), `solve(...)`, number theory (`is_prime`, `factor`, `GF(7)`), linear algebra (`matrix(...).eigenvalues()`), and group theory (`SymmetricGroup(4)`).
- That runs in a Sage environment (Docker image `sagemath/sagemath`, native package, or conda), commonly launched as `sage -n jupyter`.
- Plots via `plot(...)`, `parametric_plot(...)`, `plot3d(...)`, `parametric_plot3d(...)`.
- Typical final artifact: **computed results** and rendered **2D/3D plots** displayed inline in a notebook.

## Why
- Reach for SageMath when you need a broad, batteries-included mathematics environment spanning many domains (number theory, abstract algebra, finite fields, group theory) in one system, not just symbolic calculus.
- Main tradeoff: it is a large, heavyweight distribution — best installed via Docker/conda — versus a single focused library.
- Relative to its siblings: SageMath is the full computer-algebra *system* that subsumes and integrates libraries like `sympy` (which it can use under the hood); reach for SymPy when you just need lightweight symbolic math inside a plain Python project.

## Source
- Solution reference: `fim/solution/sagemath.md`
