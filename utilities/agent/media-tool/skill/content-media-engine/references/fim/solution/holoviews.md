# HoloViews — Declarative data visualization with swappable backends

HoloViews lets you annotate your data with a small amount of metadata (what are the key dimensions and value dimensions) and get an interactive plot "for free." You describe *what* the data is, not *how* to draw it; a backend (Bokeh, Matplotlib, or Plotly) renders it. Elements compose with `*` (overlay) and `+` (layout), and it scales to billions of points via Datashader. It is the core of the HoloViz ecosystem (Panel, hvPlot, Datashader, GeoViews).

**Current Version**: 1.19.x (current major)  **License**: BSD-3-Clause  **Runtime**: Python 3.9+; Bokeh (default) / Matplotlib / Plotly backends

## Official Resources & Documentation
- Docs: https://holoviews.org/
- Reference gallery: https://holoviews.org/reference/index.html
- User guide: https://holoviews.org/user_guide/index.html
- GitHub: https://github.com/holoviz/holoviews
- HoloViz ecosystem: https://holoviz.org/

## Installation & Setup
```bash
pip install holoviews[recommended]     # pulls bokeh, matplotlib, panel
# conda install -c pyviz holoviews bokeh
```
```python
import holoviews as hv
import numpy as np, pandas as pd
hv.extension('bokeh')          # or 'matplotlib', 'plotly'  (can list several)
```

## Core Concepts

### Elements = data + dimensions
An Element wraps data plus **key dimensions** (`kdims`, the independent/axis variables) and **value dimensions** (`vdims`, the dependent values).
```python
xs = np.linspace(0, 4*np.pi, 200)
curve = hv.Curve((xs, np.sin(xs)), kdims='x', vdims='y')
# from a DataFrame:
points = hv.Points(df, kdims=['x','y'], vdims=['category','size'])
```

### Composition operators
```python
overlay = curveA * curveB          #  *  overlays (same axes)
layout  = curveA + curveB          #  +  side-by-side panels
layout.cols(2)                     # wrap layout into 2 columns
```

### `.opts()` — the styling layer (separate from data)
```python
curve.opts(color='#4e79a7', line_width=2, width=600, height=350, tools=['hover'])
points.opts(hv.opts.Points(color='category', cmap='Category10', size=6, tools=['hover']))
```

## Elements (the "chart types")
- **Charts**: `Curve`, `Scatter`, `Points`, `Area`, `Bars`, `Histogram`, `Spikes`, `ErrorBars`, `Spread`, `Step`.
- **Statistical**: `BoxWhisker`, `Violin`, `Distribution` (KDE), `Bivariate`, `HexTiles`.
- **Raster/grid**: `Image`, `RGB`, `HeatMap`, `QuadMesh`, `Raster`, `Contours`.
- **Network/relational**: `Graph`, `Nodes`, `Chord`, `Sankey`, `TriMesh`.
- **Geographic** (via GeoViews): `gv.Points`, `gv.Polygons` on tile sources.
- **Annotations**: `HLine`, `VLine`, `Text`, `Arrow`, `Bounds`, `Path`.
- **Tabular**: `Table`, `Dataset` (the columnar base).

## Containers
- `Overlay` (`*`), `Layout` (`+`), `GridSpace` (2D grid of plots by dimension), `HoloMap` (dict of plots keyed by dimension → widgets/animation), `DynamicMap` (lazy, callback-generated frames), `NdOverlay`/`NdLayout` (multi-dimensional collections).

## How-To

### How to set colors / palette / theme
Color is set via `.opts()`; palettes come from `bokeh.palettes` / matplotlib colormaps.
```python
# 1) Constant color
hv.Curve(data).opts(color='#4e79a7')

# 2) Color by a value dimension (categorical or continuous)
hv.Points(df, ['x','y'], 'category').opts(color='category', cmap='Category10', colorbar=False)
hv.Points(df, ['x','y'], 'score').opts(color='score', cmap='viridis', colorbar=True)

# 3) Per-type defaults for the whole session
hv.opts.defaults(
    hv.opts.Curve(color='#4e79a7', line_width=2, width=600, height=350),
    hv.opts.Scatter(cmap='viridis', size=6, tools=['hover']),
)

# 4) Explicit categorical map
hv.Bars(df, 'cat', 'val').opts(cmap={'A':'#4e79a7','B':'#e15759'}, color='cat')
```
`cmap` accepts a named colormap string, a list of hex colors, or a dict. Bokeh backend also honors `bgcolor`, `gridstyle`, and `fontscale` opts for theming.

### How to switch rendering backend
```python
hv.extension('bokeh', 'matplotlib')   # register both
hv.output(curve, backend='matplotlib')  # render this one with matplotlib
# global default:
hv.Store.set_current_backend('plotly')
```
Same data object renders in any registered backend — swap `bokeh` (interactive), `matplotlib` (print), `plotly` (3D/interactive).

### How to build interactive widgets (HoloMap / DynamicMap)
```python
def sine(freq, phase):
    return hv.Curve((xs, np.sin(freq*xs + phase)), 'x', 'y')
dmap = hv.DynamicMap(sine, kdims=['freq','phase'])
dmap = dmap.redim.range(freq=(1,5), phase=(0, np.pi))   # sliders appear automatically
```

### How to render huge datasets (Datashader)
```python
from holoviews.operation.datashader import datashade, rasterize
big = hv.Points(million_row_df, ['x','y'])
shaded = datashade(big, cmap='fire')      # server-side rasterize, then display
# rasterize() keeps a colorbar/hover-able aggregate:
agg = rasterize(big).opts(cmap='viridis', colorbar=True)
```

### How to save / export
```python
hv.save(curve, 'plot.html')                       # interactive (bokeh)
hv.save(curve, 'plot.png', backend='matplotlib')  # static raster
hv.save(layout, 'plot.svg', backend='matplotlib')
```

## Do's and Don'ts

### ✅ Do
- Declare `kdims`/`vdims` explicitly so overlays, colorbars, and hover know your variables.
- Keep data and styling separate: build the Element, then `.opts()` for appearance.
- Use `rasterize`/`datashade` for anything over ~100k points.
- Set `hv.opts.defaults(...)` once for consistent look across a notebook/app.

### ❌ Don't
- Don't confuse `.opts()` (non-destructive styling) with old `.options()`/`%%opts` magics — use `.opts()`.
- Don't overlay Elements with incompatible dimensions — axis mismatch produces confusing plots.
- Don't expect every opt to exist on every backend — some are Bokeh-only or Matplotlib-only.
- Don't render millions of raw glyphs — the browser will hang; datashade instead.

## Styling, Theming & Customization
- `.opts()` per object; `hv.opts.defaults(...)` per type globally.
- Backend-specific opts: Bokeh (`tools`, `toolbar`, `active_tools`, `hover_cols`), Matplotlib (`fig_size`, `aspect`), Plotly (`camera`).
- Dimension formatting: `hv.Dimension('price', unit='$', value_format='%.2f')`.
- Compose with **Panel** (`pn.panel(hv_obj)`) for full dashboards with widgets/layout.

## Advanced Features
- **DynamicMap + streams**: `hv.streams.Tap`, `RangeXY`, `Selection1D` feed interactions back into Python callbacks (linked, live plots).
- **Datashader**: aggregate billions of points into rasters (`datashade`, `rasterize`, `dynspread`).
- **GeoViews**: geographic elements, projections, and tile sources on top of HoloViews.
- **hvPlot**: `.hvplot()` accessor on pandas/xarray/dask for instant HoloViews plots.
- **Panel**: turn HoloViews objects into deployable web apps.

## Integration Notes
- **hvPlot**: `import hvplot.pandas` gives `df.hvplot.line(x=, y=, by=)` — instant HoloViews from pandas/xarray/dask/geopandas.
- **Panel**: `pn.panel(hv_obj)` embeds any HoloViews object in a dashboard; combine with widgets and `pn.bind`.
- **Jupyter**: renders inline after `hv.extension('bokeh')`; `hv.output(...)` controls size/backend per cell.
- **xarray**: `hv.Dataset(xr_data)` wraps labeled N-D arrays; `.to(hv.Image, ['x','y'])` slices to plots.
- **GeoViews**: geographic extension (`import geoviews as gv`) adds projections and tile sources.

### How to link plots with a shared selection stream
```python
import holoviews as hv
from holoviews import streams
points = hv.Points(df, ['x','y'])
sel = streams.Selection1D(source=points)
def selected_table(index):
    rows = df.iloc[index] if index else df.iloc[:0]
    return hv.Table(rows)
layout = points + hv.DynamicMap(selected_table, streams=[sel])
```

## Common Pitfalls & Troubleshooting
- Blank/no display → forgot `hv.extension('bokeh')` at the top.
- Opts "not applying" → wrong element type in `hv.opts.<Type>(...)`, or option is backend-specific.
- Hover shows nothing useful → add `vdims` and `tools=['hover']` (Bokeh).
- Slow/frozen → too many glyphs; use `rasterize`/`datashade`.
- Colorbar missing → color must map a continuous `vdim`; set `colorbar=True`.

## Best For / Avoid For
`exploratory-data-analysis`, `backend-flexible-viz`, `big-data-datashader`, `interactive-notebooks`, `linked-brushing`, `panel-dashboards` — choose HoloViews.
Avoid for: `one-off-static-figure` (matplotlib direct), `fine-pixel-control`, `non-python`, `minimal-dependency` builds.

## See Also
- `bokeh.md` — the default rendering backend
- `matplotlib.md` / `plotly-python.md` — the other backends
- `seaborn.md` — statistical plotting alternative
- `../use-case/data-visualization.md`
