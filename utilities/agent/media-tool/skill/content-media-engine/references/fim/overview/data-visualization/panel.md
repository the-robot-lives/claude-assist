# Panel

## What
Panel is HoloViz's high-level Python framework for interactive dashboards and web apps, built on Bokeh. It connects widgets to plots, images, tables, or text with a reactive programming model and works across many plotting backends. BSD-3-Clause licensed.

## How
- The LLM emits Python using Panel components and a reactive/callback model that binds widgets to outputs; it renders objects from Matplotlib, Plotly, Bokeh, Altair, HoloViews, and more.
- Rendered by `pip install panel` (or `panel[recommended]` / `panel[all]`, also on conda-forge); develop in Jupyter and deploy to servers/containers/cloud without vendor lock-in. Includes caching, async support, and OAuth for enterprise auth.
- Final artifact: a served interactive dashboard/web app.

## Why
- Reach for Panel when you need a multi-backend dashboard framework that plugs into the whole scientific-Python and HoloViz stack (HoloViews, Datashader, GeoViews) with production features (security, scaling, async, caching).
- Tradeoffs: large datasets (>1M rows) and complex dashboards can be slow/memory-heavy, limited mobile optimization and SEO, requires a Python server (not static hosting), and a large dependency tree.
- Versus Streamlit/Dash its distinguishing strength is backend-agnostic composition and tight HoloViz integration rather than a single charting stack.

## Source
- Solution reference: `fim/solution/panel.md`
