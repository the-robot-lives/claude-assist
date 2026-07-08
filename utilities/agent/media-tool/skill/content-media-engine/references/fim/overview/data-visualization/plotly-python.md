# Plotly (Python)

## What
Plotly for Python is an interactive plotting library with web-based output. It offers a high-level Express API (`plotly.express`) and a low-level Graph Objects API (`plotly.graph_objects`), covering scatter/line/bar/pie, 3D scatter/surface/mesh, maps, statistical plots, heatmaps, and subplots.

## How
- The LLM emits Python: `px.scatter(df, ...)` for quick charts or `go.Figure()` with `add_trace(...)` and `update_layout(...)` for fine control; `fig.show()` displays.
- Rendered by `pip install plotly` (plus `kaleido` for static export); figures show inline in Jupyter, save to standalone HTML via `fig.write_html('plot.html')`, or export to PNG via `fig.write_image('plot.png')`.
- Final artifact: interactive HTML plots (zoom/pan/hover) or exported static images.

## Why
- Reach for Plotly Python when you want interactive, web-friendly plots — including built-in 3D and geographic maps — that export cleanly to HTML for sharing.
- Tradeoffs: heavier than matplotlib for simple static output, and static export needs the extra `kaleido` dependency.
- It is the charting engine behind Dash; versus matplotlib/seaborn it trades static publication control for browser interactivity, and it shares its rendering model with Plotly.js.

## Source
- Solution reference: `fim/solution/plotly-python.md`
