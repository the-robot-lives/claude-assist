# HoloViews

## What
HoloViews is a Python library for declarative data analysis and visualization where you annotate data and get automatic plots. It abstracts over multiple rendering backends (Bokeh, Matplotlib, Plotly) with a compact algebra of elements and containers.

## How
- The LLM emits Python: elements (`hv.Curve`, `hv.Points`, `hv.Bars`, `hv.Image`) combined with overlay (`*`) and layout (`+`) operators, with `hv.extension('bokeh')` selecting the backend.
- Rendered by `pip install holoviews bokeh` (matplotlib/plotly optional); plots display in Jupyter, and `hv.save()` writes HTML (Bokeh) or PNG (matplotlib backend). `datashade()`/`rasterize()` handle big data; `DynamicMap` adds interactive widgets.
- Final artifact: interactive HTML plots or static images, depending on backend.

## Why
- Reach for HoloViews when you want minimal, declarative plotting that swaps backends freely and scales to large datasets via Datashader operations — ideal for exploratory analysis in notebooks.
- Tradeoffs: the element/container algebra is its own concept to learn, and output characteristics vary by chosen backend.
- It sits in the HoloViz stack atop Bokeh; Panel wraps it for full dashboards, and it is higher-level than calling Bokeh or matplotlib directly.

## Source
- Solution reference: `fim/solution/holoviews.md`
