# Bokeh — Interactive browser visualization from Python

Bokeh is a Python library that emits interactive charts rendered by BokehJS in the browser. You add *glyphs* (line, circle, vbar, …) to a `figure`, attach tools (pan/zoom/hover/select), and either save a standalone HTML file, embed in notebooks, or serve live-updating apps via the Bokeh server. It targets rich interactivity and streaming/large data without writing JavaScript.

**Current Version**: Bokeh 3.x (current major)  **License**: BSD-3-Clause  **Runtime**: Python 3.9+ authoring; BokehJS renders in-browser (Canvas/WebGL)

## Official Resources & Documentation
- Docs: https://docs.bokeh.org/en/latest/
- Gallery: https://docs.bokeh.org/en/latest/docs/gallery.html
- Reference: https://docs.bokeh.org/en/latest/docs/reference.html
- GitHub: https://github.com/bokeh/bokeh

## Installation & Setup
```bash
pip install bokeh          # 3.x
pip install pandas         # recommended
# conda install bokeh
```
```python
from bokeh.plotting import figure, show, output_file, save
from bokeh.io import output_notebook          # Jupyter inline
from bokeh.models import HoverTool, ColumnDataSource
```

## Core API Reference

### figure + glyphs
```python
p = figure(title="Sine", x_axis_label="x", y_axis_label="y",
           width=700, height=400, tools="pan,box_zoom,wheel_zoom,reset,save")
import numpy as np
x = np.linspace(0, 4*np.pi, 200); y = np.sin(x)
p.line(x, y, legend_label="sin(x)", line_width=2, color="#4e79a7")
p.scatter(x[::10], y[::10], size=8, color="#e15759", alpha=0.6, marker="circle")
show(p)                    # opens/embeds; save(p) writes the output_file
```

### ColumnDataSource (the recommended data container)
```python
from bokeh.models import ColumnDataSource
source = ColumnDataSource(data=dict(x=x, y=y, cat=cats))
p.vbar(x='x', top='y', width=0.8, source=source, legend_field='cat')
# CDS enables hover field refs, linked selection, and streaming:
source.stream(new_data, rollover=200)      # live append, keep last 200
source.patch({'y': [(0, 99)]})             # in-place update
```

## Glyph Methods (the "chart types")
- **Lines/areas**: `line`, `multi_line`, `step`, `varea`, `harea`, `patch`, `patches`.
- **Markers**: `scatter` (marker=`circle`,`square`,`triangle`,`asterisk`,`x`,`diamond`,...), plus dedicated `circle`, `square`, `triangle`.
- **Bars/rects**: `vbar`, `hbar`, `quad`, `rect`, `block`, `hbar_stack`, `vbar_stack`.
- **Wedges**: `wedge`, `annular_wedge`, `annulus`, `arc` (pie/donut).
- **Segments/spans**: `segment`, `ray`, `span` (via model), `hspan`/`vspan`.
- **Images**: `image`, `image_rgba`, `image_url` (heatmaps/rasters).
- **Higher-level** (`bokeh.plotting`/`bokeh.transform`): `hexbin`, and via `bokeh.models` glyphs for graphs (`GraphRenderer`) and geo (`GeoJSONDataSource`, tile providers).
Bar/hist helpers use numpy: `hist, edges = np.histogram(y, bins=20); p.quad(top=hist, bottom=0, left=edges[:-1], right=edges[1:])`.

## Axes & Ranges
```python
from bokeh.models import Range1d, LinearAxis, DatetimeTickFormatter, NumeralTickFormatter
p.x_range = Range1d(0, 10)
p.xaxis.axis_label = "Date"
p.xaxis[0].formatter = DatetimeTickFormatter(days="%b %d")
p.yaxis.formatter = NumeralTickFormatter(format="$0,0")
p.xaxis.major_label_orientation = 0.8          # radians
# log axis:
p_log = figure(y_axis_type="log")
# second y axis:
p.extra_y_ranges = {"rhs": Range1d(0, 100)}
p.add_layout(LinearAxis(y_range_name="rhs", axis_label="Right"), 'right')
p.line(x, y2, y_range_name="rhs")
```

## Tools, Legends, Tooltips
```python
from bokeh.models import HoverTool
hover = HoverTool(tooltips=[("x", "@x"), ("y", "@y{0.00}"), ("cat", "@cat")],
                  mode="vline")
p.add_tools(hover)
# toolbar tools: pan, box_zoom, wheel_zoom, lasso_select, box_select, tap, crosshair, reset, save, undo/redo
p.legend.location = "top_left"
p.legend.click_policy = "hide"     # or "mute" — interactive legend
```
Tooltip field syntax: `@field` (data column), `$x`/`$y` (cursor), `@field{0.0%}` (number format), `$name`, `@img{safe}` (HTML).

## How-To

### How to set colors / palette / theme
```python
from bokeh.palettes import Category10, Viridis256, Spectral6
from bokeh.transform import factor_cmap, linear_cmap

# 1) Constant / per-glyph color
p.line(x, y, color="#4e79a7")

# 2) Categorical color mapping (color by a factor column)
cats = ['A','B','C']
p.vbar(x='name', top='val', width=0.8, source=src,
       fill_color=factor_cmap('name', palette=Category10[3], factors=cats))

# 3) Continuous color mapping + colorbar
mapper = linear_cmap('value', palette=Viridis256, low=0, high=100)
r = p.scatter('x','y', color=mapper, source=src, size=8)
from bokeh.models import ColorBar
p.add_layout(ColorBar(color_mapper=mapper['transform']), 'right')

# 4) Theme the whole document
from bokeh.io import curdoc
curdoc().theme = 'dark_minimal'    # 'caliber','dark_minimal','light_minimal','night_sky','contrast'
```
Palettes live in `bokeh.palettes`: `Category10/20`, `Set1/2/3`, `Viridis256`, `Cividis256`, `Magma256`, `Spectral`, `RdBu`, `Turbo256`.

### How to build a hover-enabled bar chart from a DataFrame
```python
src = ColumnDataSource(df)
p = figure(x_range=list(df['name']), height=350, tools="")
p.vbar(x='name', top='sales', width=0.8, source=src, fill_color="#4e79a7")
p.add_tools(HoverTool(tooltips=[("Sales","@sales{$0,0}")]))
p.xgrid.grid_line_color = None; p.y_range.start = 0
```

### How to lay out multiple plots
```python
from bokeh.layouts import gridplot, row, column
grid = gridplot([[p1, p2], [p3, None]], width=350, height=250)
show(column(row(p1, p2), p3))
```

### How to build a live server app
```python
# app.py  ->  run with:  bokeh serve --show app.py
from bokeh.plotting import figure, curdoc
from bokeh.models import Slider
slider = Slider(start=1, end=10, value=1, step=1, title="freq")
p = figure(); line = p.line(x, np.sin(x))
def update(attr, old, new): line.data_source.data['y'] = np.sin(new * x)
slider.on_change('value', update)
curdoc().add_root(column(slider, p))
```

### How to export static images
```python
from bokeh.io import export_png, export_svg   # needs `selenium` + a webdriver (chromedriver/geckodriver)
export_png(p, filename="plot.png")
p.output_backend = "svg"; export_svg(p, filename="plot.svg")
```

## Do's and Don'ts

### ✅ Do
- Use `ColumnDataSource` for anything interactive — hover fields, linked brushing, and streaming all depend on it.
- Set `output_backend="webgl"` for large scatter/line data.
- Use `legend.click_policy="hide"` for instantly interactive legends.
- Prefer the Bokeh server for anything requiring Python callbacks on interaction.

### ❌ Don't
- Don't expect Python callbacks in a *static* HTML export — only `CustomJS` runs there; real Python logic needs the Bokeh server.
- Don't forget `output_file()`/`output_notebook()` before `show()` or output goes nowhere useful.
- Don't PNG-export without a Selenium webdriver installed — it errors.
- Don't push >100k SVG glyphs — switch to WebGL backend or datashader.

## Styling, Theming & Customization
- Document themes via `curdoc().theme`; custom themes from a dict/YAML applied to model defaults.
- Fine control: `p.title.text_font_size`, `p.xaxis.axis_label_text_color`, `p.grid.grid_line_alpha`, `p.background_fill_color`, `p.border_fill_color`, `p.outline_line_color`.
- `p.toolbar.logo = None` hides the Bokeh logo; `p.toolbar_location = "above"`.

## Advanced Features
- **Bokeh server**: real-time Python-driven apps, periodic callbacks (`curdoc().add_periodic_callback`), streaming.
- **CustomJS**: attach JS callbacks to widgets/events for interactivity without a server.
- **Linked brushing/panning**: shared `ColumnDataSource` or shared ranges across figures.
- **Datashader integration**: render billions of points as server-side rasters, then overlay.
- **Widgets**: `Slider`, `Select`, `Button`, `DataTable`, `Tabs`, `DateRangeSlider` for dashboards.
- **GeoViews/HoloViews**: higher-level libraries that emit Bokeh.

## Integration Notes
- **Jupyter/JupyterLab**: `output_notebook()` once, then `show(p)` inline; `push_notebook` for live updates.
- **Embedding in web apps**: `bokeh.embed.components(p)` returns `(script, div)` to drop into any HTML template; `file_html(p, CDN, "title")` for a standalone page.
- **Flask/Django**: serve `components()` output, or embed a running Bokeh server app via `server_document(url)`.
- **Panel/HoloViews**: both render to Bokeh — build higher-level dashboards that emit Bokeh models.
- **pandas**: pass a DataFrame to `ColumnDataSource(df)`; column names become `@field` references.

### How to add linked brushing across two plots
```python
src = ColumnDataSource(df)
p1 = figure(tools="box_select,lasso_select,reset"); p1.scatter('x','y', source=src)
p2 = figure(tools="box_select,lasso_select,reset"); p2.scatter('x','z', source=src)
show(row(p1, p2))   # selecting in one highlights the same rows in the other (shared CDS)
```

## Common Pitfalls & Troubleshooting
- `show()` does nothing → missing `output_file`/`output_notebook`; in scripts it opens a browser tab.
- Hover shows `???` → tooltip references a column not in the CDS.
- PNG/SVG export fails → install `selenium` + matching webdriver.
- Categorical bars mis-ordered → set `figure(x_range=explicit_list)`.
- Slow with big data → `output_backend="webgl"`, decimate, or use datashader.

## Best For / Avoid For
`interactive-python-dashboards`, `streaming-data`, `linked-brushing`, `server-apps`, `large-scatter-webgl`, `custom-tooltips` — choose Bokeh.
Avoid for: `quick-static-figures` (matplotlib), `pure-declarative-specs` (Altair/Vega-Lite), `3D`, `no-python-runtime` deploys.

## See Also
- `holoviews.md` — higher-level API that renders via Bokeh
- `plotly-python.md` — interactive alternative
- `matplotlib.md` / `seaborn.md` — static Python plotting
- `../use-case/data-visualization.md`
