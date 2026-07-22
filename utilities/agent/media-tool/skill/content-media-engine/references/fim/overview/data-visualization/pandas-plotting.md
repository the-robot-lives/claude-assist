# Pandas Plotting

## What
Pandas plotting is the built-in `.plot()` accessor on DataFrame and Series objects, layered on matplotlib. It turns tabular data into charts (line, bar, scatter, histogram, box, etc.) with minimal code for rapid exploratory analysis.

## How
- The LLM emits Python: `df.plot(...)` or typed accessors like `df.plot.scatter(...)`, with optional `backend=` to route to matplotlib (default), plotly, or hvplot.
- Rendered by `pip install pandas matplotlib`; plots display inline in notebooks or via matplotlib's show/savefig. Pandas 2.0+ supports `df.plot(backend='plotly')` for native alternate backends.
- Final artifact: matplotlib figures (static images) by default, or interactive output through an alternate backend.

## Why
- Reach for pandas plotting for the fastest path from a DataFrame to a chart — single-line plots with automatic handling of dtypes, index-as-x-axis, groupby, and datetime data during EDA.
- Tradeoffs: limited complex-layout/3D/animation support (drop to matplotlib directly), fewer themes than seaborn/plotly, and slowdowns on very large datasets (>1M points); it inherits matplotlib's constraints.
- It is a convenience wrapper over matplotlib; when you outgrow it, move to matplotlib for control or seaborn for statistical polish.

## Source
- Solution reference: `fim/solution/pandas-plotting.md`
