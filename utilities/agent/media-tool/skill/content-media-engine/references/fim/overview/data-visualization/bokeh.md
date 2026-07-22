# Bokeh

## What
Bokeh is a Python interactive visualization library that targets web browsers. It builds plots with tools (hover, pan, zoom), layouts, and widgets, and supports streaming data and server-side apps.

## How
- The LLM emits Python using `bokeh.plotting` (`figure()`, glyph methods like `p.line`/`p.circle`), models such as `HoverTool`, and layouts (`row`, `column`, `gridplot`).
- Rendered by `pip install bokeh`; `show(p)` opens the plot in a browser, `output_file('plot.html')` saves standalone HTML, and `output_notebook()` embeds in Jupyter with `push_notebook` for live updates. `bokeh.server` runs interactive server apps.
- Final artifact: interactive HTML/JS plots (standalone file, notebook, or served app).

## Why
- Reach for Bokeh when you want browser-based interactive Python plots with hover/widgets, streaming data, or a Python-driven server application.
- Tradeoffs: interactivity centers on the browser; heavy real-time apps depend on server resources (per the Panel/HoloViz family it underpins).
- It is the rendering engine beneath HoloViews and Panel; versus matplotlib it favors interactivity over static publication figures.

## Source
- Solution reference: `fim/solution/bokeh.md`
