# Plotly (Python) — Interactive, web-native charts from Python

`plotly` for Python produces the same interactive figures as Plotly.js, driven by Python. Two APIs: **Plotly Express** (`px`, one-liners over tidy DataFrames) and **Graph Objects** (`go`, explicit figure construction). Output is an HTML/JS figure that renders inline in Jupyter, in the browser, or exports to static images via Kaleido.

**Current Version**: plotly 5.24.x (current major)  **License**: MIT  **Runtime**: Python 3.8+; renders via plotly.js

## Official Resources & Documentation
- Docs: https://plotly.com/python/
- Full reference: https://plotly.com/python-api-reference/
- Express: https://plotly.com/python/plotly-express/
- Colorscales: https://plotly.com/python/builtin-colorscales/
- GitHub: https://github.com/plotly/plotly.py

## Installation & Setup
```bash
pip install plotly            # core (5.24.x)
pip install pandas            # recommended for px
pip install kaleido           # static PNG/SVG/PDF export (fig.write_image)
pip install "nbformat>=4.2"   # Jupyter inline rendering
```
```python
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
```

## Core API Reference

### Plotly Express (high-level)
```python
df = px.data.gapminder().query("year == 2007")
fig = px.scatter(
    df, x="gdpPercap", y="lifeExp",
    size="pop", color="continent",           # color = categorical/continuous column
    hover_name="country", log_x=True,
    size_max=60, title="GDP vs Life Expectancy",
    color_discrete_sequence=px.colors.qualitative.Set2,
)
fig.show()
```
Express functions: `scatter`, `line`, `bar`, `histogram`, `box`, `violin`, `strip`, `ecdf`, `area`, `pie`, `sunburst`, `treemap`, `icicle`, `funnel`, `scatter_3d`, `line_3d`, `scatter_matrix`, `parallel_coordinates`, `parallel_categories`, `density_heatmap`, `density_contour`, `imshow`, `scatter_geo`, `choropleth`, `scatter_mapbox`, `choropleth_mapbox`, `scatter_ternary`, `line_polar`, `bar_polar`.

### Graph Objects (low-level, full control)
```python
fig = go.Figure()
fig.add_trace(go.Scatter(x=x, y=y1, mode="lines+markers", name="Actual",
                         line=dict(color="#4e79a7", width=2)))
fig.add_trace(go.Bar(x=x, y=y2, name="Budget", marker_color="#f28e2b"))
fig.update_layout(title="Mixed", xaxis_title="Month", yaxis_title="USD",
                  template="plotly_white", legend=dict(orientation="h"))
fig.show()
```
Every `px` figure is a `go.Figure` — mix them: build with `px`, then `fig.add_trace(...)`, `fig.update_layout(...)`, `fig.update_traces(...)`.

### The `fig` object
```python
fig.update_layout(...)      # layout attributes
fig.update_xaxes(...)       # all x axes
fig.update_traces(marker=dict(size=10), selector=dict(type="scatter"))
fig.add_hline(y=0, line_dash="dash"); fig.add_vrect(x0=2, x1=4, fillcolor="gray", opacity=0.2)
fig.add_annotation(x=3, y=10, text="peak", showarrow=True)
```

## Chart / Trace Types
Same surface as plotly.js: 2D cartesian, statistical (`box`, `violin`, `histogram`), `heatmap`/`contour`/`imshow`, financial (`Candlestick`, `Ohlc`, `Waterfall`, `Funnel`), hierarchical (`Sunburst`, `Treemap`, `Icicle`, `Sankey`), 3D (`Scatter3d`, `Surface`, `Mesh3d`, `Cone`, `Isosurface`, `Volume`), maps (`Scattergeo`, `Choropleth`, `Scattermapbox`, `Densitymapbox`), `Indicator` (KPI/gauge), `Table`, `Scattergl` (WebGL large-data).

## Scales & Axes
```python
fig.update_xaxes(type="log", title_text="Revenue", tickformat="$,.0f",
                 range=[0, 6], showgrid=True, gridcolor="rgba(0,0,0,0.08)")
fig.update_yaxes(type="linear", rangemode="tozero", tickformat=".1%")
# Dual axis via graph objects:
fig.update_layout(yaxis2=dict(overlaying="y", side="right", title="Secondary"))
fig.add_trace(go.Scatter(x=x, y=y, yaxis="y2"))
```

## Legends, Hover, Interactivity
```python
fig.update_layout(
    legend=dict(orientation="h", y=1.1, x=0, title_text=""),
    hovermode="x unified",
)
fig.update_traces(hovertemplate="<b>%{x}</b><br>%{y:$,.0f}<extra></extra>")
```

## How-To

### How to set colors / palette / theme
```python
# 1) Categorical (discrete) sequence in Express
fig = px.bar(df, x="cat", y="val", color="cat",
             color_discrete_sequence=px.colors.qualitative.Bold)
# map specific categories:
fig = px.bar(df, x="cat", y="val", color="cat",
             color_discrete_map={"A":"#4e79a7","B":"#e15759"})

# 2) Continuous colorscale
fig = px.scatter(df, x="x", y="y", color="score",
                 color_continuous_scale="Viridis", range_color=[0,1])

# 3) Global theme via template
import plotly.io as pio
pio.templates.default = "plotly_dark"      # plotly, plotly_white, plotly_dark, ggplot2, seaborn, simple_white, presentation
# custom template:
pio.templates["brand"] = go.layout.Template(
    layout=dict(colorway=["#4e79a7","#f28e2b","#e15759","#76b7b2"],
                font=dict(family="Inter", color="#e5e7eb"),
                paper_bgcolor="#111", plot_bgcolor="#111"))
pio.templates.default = "brand"
```
Palette groups: `px.colors.qualitative.*` (Plotly, D3, Set1-3, Bold, Pastel), `px.colors.sequential.*` (Viridis, Blues, Plasma), `px.colors.diverging.*` (RdBu, Spectral, Portland).

### How to make faceted small multiples
```python
fig = px.line(df, x="year", y="value", color="metric",
              facet_col="region", facet_row="segment", facet_col_wrap=3)
fig.for_each_annotation(lambda a: a.update(text=a.text.split("=")[-1]))
```

### How to build subplots with mixed types
```python
fig = make_subplots(rows=2, cols=1, shared_xaxes=True,
                    specs=[[{"type":"xy"}],[{"type":"xy"}]],
                    subplot_titles=("Price","Volume"))
fig.add_trace(go.Scatter(x=x, y=price), row=1, col=1)
fig.add_trace(go.Bar(x=x, y=vol), row=2, col=1)
```

### How to export static images and standalone HTML
```python
fig.write_image("chart.png", width=1200, height=800, scale=2)   # needs kaleido
fig.write_image("chart.svg")                                     # vector
fig.write_html("chart.html", include_plotlyjs="cdn", full_html=True)
fig.to_json()   # serialize the figure spec
```

## Do's and Don'ts

### ✅ Do
- Start with `px` for tidy DataFrames; drop to `go` only when you need attributes `px` doesn't expose.
- Use `fig.update_traces(selector=...)` to target specific traces rather than rebuilding.
- Set `template` once globally via `pio.templates.default` for consistent branding.
- Use `Scattergl` / `density_heatmap` for large point clouds.

### ❌ Don't
- Don't forget `kaleido` before `write_image` — it errors otherwise.
- Don't pass wide (untidy) data to `px` and expect color grouping — melt to long form first (`pd.melt`).
- Don't render 100k SVG points with `px.scatter` — use `render_mode="webgl"` or `Scattergl`.
- Don't rely on `fig.show()` in a plain script without a browser/renderer configured — set `pio.renderers.default` (`"browser"`, `"notebook"`, `"png"`).

## Styling, Theming & Customization
- Templates: `plotly`, `plotly_white`, `plotly_dark`, `ggplot2`, `seaborn`, `simple_white`, `presentation`, `none`. Combine: `template="plotly_white+presentation"`.
- `fig.update_layout(font=, colorway=, margin=dict(l=40,r=20,t=60,b=40))`.
- Annotations/shapes: `add_hline`, `add_vline`, `add_hrect`, `add_vrect`, `add_shape`, `add_annotation`.
- Colorbar: `fig.update_coloraxes(colorbar_title="...")`.

## Advanced Features
- **Dash**: build interactive analytical web apps on top of these figures (`pip install dash`).
- **FigureWidget**: `go.FigureWidget` gives live, event-driven figures inside Jupyter (`fig.data[0].on_click`).
- **Animations**: `px.scatter(..., animation_frame="year", animation_group="country")` adds a play slider.
- **Frames/transitions** via `go.Frame` for manual animation.
- **Mapbox**: `scatter_mapbox`/`choropleth_mapbox` with `mapbox_style="carto-positron"` (no token) or Mapbox token styles.

## Integration Notes
- **Jupyter**: figures render inline automatically (needs `nbformat`); `FigureWidget` gives event callbacks.
- **Dash**: `dcc.Graph(figure=fig)` embeds any figure in a reactive web app; callbacks return new figures.
- **Streamlit**: `st.plotly_chart(fig, use_container_width=True)`.
- **Static reports**: `fig.write_html(..., include_plotlyjs="cdn")` keeps files small; `write_image` (Kaleido) for PNG/PDF/SVG in LaTeX/Word.
- **pandas**: `df.plot(backend="plotly")` routes pandas `.plot` through Plotly.

### How to render a KPI indicator / gauge
```python
fig = go.Figure(go.Indicator(
    mode="gauge+number+delta", value=72,
    delta={"reference": 65}, gauge={"axis": {"range": [0, 100]}},
    title={"text": "Score"}))
```

## Common Pitfalls & Troubleshooting
- `ValueError: Image export requires kaleido` → `pip install kaleido`.
- Blank output in Jupyter → install `nbformat`, restart kernel; check `pio.renderers`.
- Wrong color grouping → data must be long/tidy for `px` color mapping.
- Static export fonts differ → embed fonts or use system fonts available to Kaleido.
- Huge notebook size → `include_plotlyjs="cdn"` when writing HTML instead of inlining the 3MB library.

## Best For / Avoid For
`jupyter-eda`, `interactive-dashboards`, `dash-apps`, `scientific-3d`, `statistical-charts`, `maps`, `shareable-html` — choose Plotly Python.
Avoid for: `publication-static-only` (matplotlib gives finer print control), `ultra-minimal-deploys`, `pure-R-workflows` (use ggplot2).

## See Also
- `plotly_js.md` — the JS renderer underneath
- `matplotlib.md` / `seaborn.md` — static Python plotting
- `bokeh.md` / `holoviews.md` — other interactive Python options
- `../use-case/data-visualization.md`
