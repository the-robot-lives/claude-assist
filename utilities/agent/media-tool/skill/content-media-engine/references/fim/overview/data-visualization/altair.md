# Altair

## What
Altair is a declarative statistical visualization library for Python, built on Vega-Lite. Python code compiles to Vega-Lite JSON specifications, which render as interactive web-based visualizations. BSD-3-Clause licensed.

## How
- The LLM emits Python using Altair's grammar of graphics: `alt.Chart(data).mark_point().encode(x=..., y=..., color=...).properties(...)` over a pandas DataFrame.
- Rendered by `pip install altair pandas`; charts display inline in Jupyter or via `chart.show()`. Static export to PNG/SVG uses `altair_saver` / `vl-convert-python`; charts also compile to portable Vega-Lite JSON for web deployment.
- Final artifact: interactive web visualization (SVG/Canvas), portable Vega-Lite JSON, or exported PNG/SVG.

## Why
- Reach for Altair for exploratory data analysis, statistical visualizations, and Jupyter-based work where a declarative grammar and native selections/brushing/linking are valuable, and where compiling to portable JSON specs aids web deployment.
- Tradeoffs: grammar-of-graphics paradigm shift, less pixel-perfect control than matplotlib, requires a JavaScript runtime to render, no native 3D, limited animation, and some exports need extra system dependencies (Chrome/Node.js).
- It is the Pythonic front-end to Vega-Lite; versus matplotlib/seaborn it favors interactivity and declarative composition over low-level styling control.

## Source
- Solution reference: `fim/solution/altair.md`
