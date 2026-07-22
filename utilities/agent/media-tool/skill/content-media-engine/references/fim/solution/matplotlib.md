# Matplotlib — The foundational Python plotting library

Matplotlib is the cornerstone of Python visualization: a low-level, highly controllable 2D plotting library producing publication-quality static figures (with limited interactivity). It offers two API styles — the stateful `pyplot` interface and the explicit object-oriented `Figure`/`Axes` API — and exports to PNG, SVG, PDF, and EPS. Seaborn, pandas `.plot`, and many others build on it.

**Current Version**: 3.9.x (current major)  **License**: Matplotlib (BSD-style, PSF-based)  **Runtime**: Python 3.9+; multiple backends (Agg, SVG, PDF, TkAgg, Qt, notebook)

## Official Resources & Documentation
- Docs: https://matplotlib.org/stable/
- Gallery: https://matplotlib.org/stable/gallery/
- Cheatsheets: https://matplotlib.org/cheatsheets/
- Colormaps: https://matplotlib.org/stable/users/explain/colors/colormaps.html
- GitHub: https://github.com/matplotlib/matplotlib

## Installation & Setup
```bash
pip install matplotlib
pip install ipympl        # interactive Jupyter widget backend
```
```python
import matplotlib.pyplot as plt
import numpy as np
# Jupyter:
# %matplotlib inline     -> static PNG
# %matplotlib widget     -> interactive (needs ipympl)
```

## Core API — two styles

### Object-oriented (recommended for anything non-trivial)
```python
fig, ax = plt.subplots(figsize=(8, 5), dpi=100)
ax.plot(x, y, label='sin', color='#4e79a7', linewidth=2)
ax.set_xlabel('x'); ax.set_ylabel('y'); ax.set_title('Sine')
ax.legend(loc='upper right'); ax.grid(True, alpha=0.3)
fig.tight_layout()
fig.savefig('out.png', dpi=300, bbox_inches='tight')
```

### pyplot (stateful, quick)
```python
plt.figure(figsize=(8,5))
plt.plot(x, y); plt.xlabel('x'); plt.title('Sine'); plt.show()
```
`fig` is the whole canvas; `ax` (Axes) is one plot region. `fig, axs = plt.subplots(2, 3)` returns an array of Axes.

## Plot Types (Axes methods)
- **Lines/areas**: `ax.plot`, `ax.step`, `ax.fill_between`, `ax.stackplot`, `ax.errorbar`.
- **Points**: `ax.scatter` (size `s`, color `c`), `ax.plot(..., 'o')`.
- **Bars**: `ax.bar`, `ax.barh`, stacked via `bottom=`, `ax.hist`, `ax.hist2d`.
- **Distribution/statistical**: `ax.boxplot`, `ax.violinplot`, `ax.hist`, `ax.hexbin`, `ax.ecdf`.
- **Categorical/parts**: `ax.pie`, `ax.bar` groups.
- **2D fields**: `ax.imshow` (raster/heatmap), `ax.matshow`, `ax.pcolormesh`, `ax.contour`, `ax.contourf`, `ax.quiver`, `ax.streamplot`.
- **3D** (`mpl_toolkits.mplot3d`): `ax.plot_surface`, `ax.scatter3D`, `ax.plot_wireframe`, `ax.bar3d`, `ax.contour3D`.
```python
from mpl_toolkits.mplot3d import Axes3D
fig = plt.figure(); ax = fig.add_subplot(projection='3d')
ax.plot_surface(X, Y, Z, cmap='viridis')
```

## Subplots & Layout
```python
fig, axs = plt.subplots(2, 2, figsize=(10, 8), sharex=True)
axs[0,0].plot(x, y); axs[0,1].scatter(x, y)
axs[1,0].hist(y, bins=20); axs[1,1].bar(['A','B','C'], [1,2,3])
fig.suptitle('Dashboard'); fig.tight_layout()
# flexible grids:
gs = fig.add_gridspec(3, 3); ax_big = fig.add_subplot(gs[0:2, :])
# modern helper:
fig, axd = plt.subplot_mosaic([['top','top'],['left','right']])
```

## Colormaps & Color
Colormap families: **perceptually uniform sequential** (`viridis`, `plasma`, `inferno`, `magma`, `cividis`), sequential (`Blues`, `YlOrRd`), diverging (`RdBu`, `coolwarm`, `seismic`), cyclic (`twilight`, `hsv`), qualitative (`tab10`, `tab20`, `Set1`, `Pastel1`).

## How-To

### How to set colors / palette / theme
```python
# 1) Explicit per-artist color (name, hex, RGB tuple, 'C0' cycle ref)
ax.plot(x, y, color='#4e79a7')
ax.bar(cats, vals, color=['#4e79a7','#f28e2b','#e15759'])

# 2) Color a scatter continuously by a value + colorbar
sc = ax.scatter(x, y, c=z, cmap='viridis', s=40)
fig.colorbar(sc, ax=ax, label='z')

# 3) Set the default color cycle (the palette every plot() uses in order)
from cycler import cycler
plt.rcParams['axes.prop_cycle'] = cycler(color=['#4e79a7','#f28e2b','#e15759','#76b7b2'])

# 4) Apply a whole theme (stylesheet)
plt.style.use('seaborn-v0_8-darkgrid')   # or 'ggplot','fivethirtyeight','bmh','dark_background'
# combine + tweak:
plt.style.use(['dark_background'])
plt.rcParams.update({'figure.facecolor':'#111','axes.grid':True,'font.family':'Inter'})
```
List styles with `plt.style.available`. Use a context manager to scope: `with plt.style.context('ggplot'): ...`.

### How to make a grouped/stacked bar chart
```python
import numpy as np
xi = np.arange(len(cats)); w = 0.35
ax.bar(xi - w/2, series_a, w, label='A', color='#4e79a7')
ax.bar(xi + w/2, series_b, w, label='B', color='#f28e2b')
ax.set_xticks(xi); ax.set_xticklabels(cats); ax.legend()
# stacked:
ax.bar(cats, a, label='A'); ax.bar(cats, b, bottom=a, label='B')
```

### How to draw a heatmap with annotations
```python
im = ax.imshow(matrix, cmap='RdBu_r', aspect='auto')
ax.set_xticks(range(len(cols))); ax.set_xticklabels(cols, rotation=45, ha='right')
ax.set_yticks(range(len(rows))); ax.set_yticklabels(rows)
for i in range(len(rows)):
    for j in range(len(cols)):
        ax.text(j, i, f'{matrix[i,j]:.1f}', ha='center', va='center')
fig.colorbar(im)
```

### How to configure rcParams globally
```python
plt.rcParams.update({
    'figure.figsize': (8, 5), 'figure.dpi': 110, 'savefig.dpi': 300,
    'font.size': 12, 'axes.titlesize': 15, 'axes.spines.top': False,
    'axes.spines.right': False, 'legend.frameon': False, 'lines.linewidth': 2,
})
# or load a matplotlibrc file / mplstyle file
```

### How to save for print vs web
```python
fig.savefig('fig.pdf', bbox_inches='tight')                 # vector, journals
fig.savefig('fig.svg')                                      # vector, web
fig.savefig('fig.png', dpi=300, bbox_inches='tight',
            transparent=True, facecolor='white')            # raster
```

## Do's and Don'ts

### ✅ Do
- Use the OO API (`fig, ax = plt.subplots()`) for multi-panel and reusable plotting code.
- Set `bbox_inches='tight'` on `savefig` to avoid clipped labels.
- Prefer perceptually-uniform colormaps (`viridis`) over `jet`/`rainbow`.
- Call `fig.tight_layout()` or `constrained_layout=True` to prevent overlapping labels.

### ❌ Don't
- Don't mix `plt.` stateful calls with OO across functions — you lose track of the "current" axes.
- Don't leave figures open in loops (`plt.close(fig)`) — they leak memory in batch jobs.
- Don't use `jet` for scientific data — it distorts perception; use `viridis`.
- Don't rely on `plt.show()` in a headless server — set `matplotlib.use('Agg')` before importing pyplot and `savefig` instead.

## Styling, Theming & Customization
- **Stylesheets**: `plt.style.use(...)`, custom `.mplstyle` files, `plt.style.context`.
- **rcParams**: every default (fonts, colors, sizes, spines, grid, ticks) is tunable.
- **Spines/ticks**: `ax.spines['top'].set_visible(False)`, `ax.tick_params(direction='out', length=4)`.
- **Text/annotation**: `ax.annotate('peak', xy=(x,y), xytext=(x+1,y+1), arrowprops=dict(arrowstyle='->'))`, LaTeX via `r'$\alpha$'` (or full `text.usetex=True`).
- **Legends**: `ax.legend(loc=, ncol=, bbox_to_anchor=, frameon=)`.

## Advanced Features
- **Animation**: `matplotlib.animation.FuncAnimation` → GIF/MP4 (needs `pillow`/`ffmpeg`).
- **Interactive backends**: `%matplotlib widget` (ipympl), Qt/Tk for zoom/pan; event handling via `fig.canvas.mpl_connect`.
- **Transforms/twin axes**: `ax.twinx()` for dual y-axes; blended transforms for annotations.
- **mplfinance** for candlesticks; **cartopy** for geographic projections; **mpl_toolkits.mplot3d** for 3D.
- **Constrained/tight layout** and `GridSpec`/`subplot_mosaic` for complex compositions.

## Integration Notes
- **pandas**: `df.plot(kind='line'|'bar'|'hist'|'box'|'area'|'scatter', ax=ax)` is a thin matplotlib wrapper; returns an Axes you can keep styling.
- **Jupyter**: `%matplotlib inline` (static PNG), `%matplotlib widget` (interactive via ipympl), or `%matplotlib notebook` (classic). Retina: `%config InlineBackend.figure_format='retina'`.
- **Headless/CI**: set `import matplotlib; matplotlib.use('Agg')` *before* `import matplotlib.pyplot as plt`, then only `savefig` (never `show`).
- **Seaborn / sklearn / pandas** all render through matplotlib — mix them on shared `ax=` objects and export once with `fig.savefig`.
- **Animation to video**: `FuncAnimation(...).save('out.mp4', writer='ffmpeg', fps=30)` needs ffmpeg on PATH; GIF via `writer='pillow'`.
- **Web embedding**: save SVG and inline it, or render to a PNG data URI (`io.BytesIO` + `base64`).

### How to embed in a figure buffer (server response)
```python
import io, base64
buf = io.BytesIO(); fig.savefig(buf, format='png', dpi=150, bbox_inches='tight')
data_uri = 'data:image/png;base64,' + base64.b64encode(buf.getvalue()).decode()
```

### How to make an animation (line growing over time)
```python
from matplotlib.animation import FuncAnimation
fig, ax = plt.subplots(); line, = ax.plot([], [])
ax.set_xlim(0, 10); ax.set_ylim(-1, 1)
def update(frame):
    xs = np.linspace(0, frame/10, 200); line.set_data(xs, np.sin(xs)); return line,
ani = FuncAnimation(fig, update, frames=100, interval=50, blit=True)
ani.save('wave.gif', writer='pillow', fps=20)
```

## Common Pitfalls & Troubleshooting
- Nothing shows in a script → wrong backend or missing `plt.show()`; on servers use `Agg` + `savefig`.
- Labels cut off in saved file → `bbox_inches='tight'`.
- Overlapping subplots → `tight_layout()` / `constrained_layout=True`.
- Fonts differ across machines → embed with `savefig(..., metadata)` / use available fonts; for PDF set `pdf.fonttype`.
- Colorbar attaches to wrong axes → pass `ax=` or `cax=` explicitly.
- Memory growth in loops → `plt.close(fig)`.

## Best For / Avoid For
`publication-figures`, `scientific-plots`, `fine-grained-control`, `print-vector-output`, `batch-figure-generation`, `custom-composite-layouts` — choose Matplotlib.
Avoid for: `rich-web-interactivity` (Plotly/Bokeh), `quick-statistical-defaults` (seaborn on top), `big-interactive-dashboards`.

## See Also
- `seaborn.md` — statistical wrapper over matplotlib
- `plotly-python.md` / `bokeh.md` — interactive Python alternatives
- `sklearn-viz.md` — ML plots built on matplotlib
- `../use-case/data-visualization.md`
