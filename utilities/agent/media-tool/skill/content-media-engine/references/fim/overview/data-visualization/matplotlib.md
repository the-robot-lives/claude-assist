# Matplotlib

## What
Matplotlib is the comprehensive foundational plotting library for Python, producing publication-quality static figures. It covers line, scatter, bar, histogram, pie, heatmap (`imshow`), subplots, and 3D plots (via `mpl_toolkits.mplot3d`).

## How
- The LLM emits Python using `matplotlib.pyplot` (`plt.plot`, `plt.scatter`, `plt.subplots`, axis/label/title calls, `plt.show()`).
- Rendered by `pip install matplotlib`; figures display via `plt.show()`, embed in Jupyter with `%matplotlib inline` (or `%matplotlib widget` + `ipympl` for interactivity), and export with `plt.savefig('plot.png', dpi=300, bbox_inches='tight')`.
- Final artifact: static raster/vector images (PNG, and other savefig formats) or interactive notebook widgets.

## Why
- Reach for matplotlib as the low-level, maximally controllable default for Python plotting and publication figures — nearly every other Python viz library builds on or interoperates with it.
- Tradeoffs: verbose for statistical/aesthetic conveniences and static-first (interactivity requires extra tooling).
- It is the substrate for seaborn, pandas `.plot()`, and sklearn's display helpers; versus seaborn it offers control over convenience, versus Plotly/Bokeh it offers static publication quality over browser interactivity. The nested `use-case/` detail covers data-visualization and python-code-generation.

## Source
- Solution reference: `fim/solution/matplotlib.md`
- Nested use-case detail: `fim/solution/matplotlib/use-case/data-visualization.md`, `fim/solution/matplotlib/use-case/python-code-generation.md`
