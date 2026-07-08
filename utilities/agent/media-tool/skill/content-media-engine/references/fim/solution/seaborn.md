# Seaborn — Statistical data visualization over matplotlib

Seaborn is a high-level Python library that sits on top of matplotlib and pairs tightly with pandas DataFrames. It turns common statistical plots (distributions, regressions, categorical comparisons, correlation matrices) into one-liners, applies attractive defaults and palettes, and handles aggregation, error bars, and grouping automatically. Every seaborn figure is ultimately matplotlib, so you can drop down for fine control.

**Current Version**: 0.13.x (current major)  **License**: BSD-3-Clause  **Runtime**: Python 3.8+; renders via matplotlib

## Official Resources & Documentation
- Docs: https://seaborn.pydata.org/
- API: https://seaborn.pydata.org/api.html
- Gallery: https://seaborn.pydata.org/examples/index.html
- Tutorial: https://seaborn.pydata.org/tutorial.html
- GitHub: https://github.com/mwaskom/seaborn

## Installation & Setup
```bash
pip install seaborn        # 0.13.x (pulls matplotlib, pandas, numpy)
```
```python
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
sns.set_theme(style="whitegrid", palette="deep")   # apply seaborn styling globally
df = sns.load_dataset("penguins")                    # sample datasets
```

## Two families of functions

### Axes-level (draw onto a matplotlib Axes)
Return an `Axes`; combine freely with subplots. Examples: `scatterplot`, `lineplot`, `histplot`, `kdeplot`, `boxplot`, `violinplot`, `barplot`, `heatmap`.
```python
fig, ax = plt.subplots(figsize=(7,5))
sns.scatterplot(data=df, x="flipper_length_mm", y="body_mass_g",
                hue="species", size="body_mass_g", ax=ax)
```

### Figure-level (manage their own Figure + faceting)
Return a `FacetGrid`/`JointGrid`/`PairGrid`; support `col=`/`row=` faceting. Examples: `relplot`, `displot`, `catplot`, `lmplot`, `jointplot`, `pairplot`.
```python
sns.relplot(data=df, x="flipper_length_mm", y="body_mass_g",
            hue="species", col="island", kind="scatter", height=4)
```
Rule of thumb: use axes-level to place a plot in a custom layout; use figure-level for automatic small multiples.

## Plot Types by category
- **Relational** (`relplot`, `scatterplot`, `lineplot`): `lineplot` auto-aggregates repeated x with a confidence band.
- **Distributions** (`displot`, `histplot`, `kdeplot`, `ecdfplot`, `rugplot`): `kde=True`, `stat="density"`, `multiple="stack"|"dodge"|"fill"`.
- **Categorical** (`catplot`, `boxplot`, `violinplot`, `boxenplot`, `stripplot`, `swarmplot`, `barplot`, `countplot`, `pointplot`).
- **Regression** (`lmplot`, `regplot`, `residplot`): fit + CI band, `order=` polynomial, `logistic=True`, `lowess=True`.
- **Matrix** (`heatmap`, `clustermap`): correlation/matrix data; `clustermap` adds dendrograms.
- **Multi-plot grids** (`pairplot`, `jointplot`, `FacetGrid`, `PairGrid`, `JointGrid`).
- **Objects interface** (`seaborn.objects` as `so`): a newer grammar-of-graphics layer (`so.Plot(df, x=, y=).add(so.Dot())`).

## How-To

### How to set colors / palette / theme
Palette (categorical color mapping) and style (background/grid) are separate knobs.
```python
# 1) Global theme + palette
sns.set_theme(style="darkgrid", palette="Set2")
# styles: darkgrid, whitegrid, dark, white, ticks
# palettes: deep, muted, pastel, bright, dark, colorblind, or any matplotlib/named

# 2) Per-plot palette (categorical)
sns.barplot(data=df, x="species", y="body_mass_g", palette="viridis")
# explicit map:
sns.scatterplot(data=df, x="x", y="y", hue="species",
                palette={"Adelie":"#4e79a7","Gentoo":"#f28e2b","Chinstrap":"#e15759"})

# 3) Build/inspect palettes
pal = sns.color_palette("husl", 8)          # evenly-spaced hues
sns.color_palette("rocket", as_cmap=True)   # continuous colormap
sns.diverging_palette(240, 10, as_cmap=True)

# 4) Sequential/continuous hue
sns.scatterplot(data=df, x="x", y="y", hue="value", palette="flare")

# 5) Scoped context (temporary sizing/theme)
with sns.axes_style("white"), sns.plotting_context("talk"):
    sns.histplot(df, x="body_mass_g")
```
`set_context("paper"|"notebook"|"talk"|"poster")` scales fonts/lines for the medium.

### How to plot a correlation heatmap
```python
corr = df.select_dtypes("number").corr()
sns.heatmap(corr, annot=True, fmt=".2f", cmap="coolwarm", center=0,
            vmin=-1, vmax=1, square=True, linewidths=0.5, cbar_kws={"shrink":0.8})
```

### How to make faceted small multiples
```python
g = sns.catplot(data=df, x="species", y="body_mass_g", col="island",
                kind="box", height=4, aspect=0.8)
g.set_axis_labels("Species", "Mass (g)").set_titles("{col_name}")
```

### How to overlay a regression on a scatter
```python
sns.lmplot(data=df, x="flipper_length_mm", y="body_mass_g",
           hue="species", ci=95, scatter_kws={"alpha":0.5})
```

### How to combine with matplotlib for fine control
```python
fig, ax = plt.subplots(figsize=(8,5))
sns.violinplot(data=df, x="species", y="body_mass_g", ax=ax, inner="quartile")
ax.set_title("Mass by species"); ax.set_ylabel("grams")
sns.despine(ax=ax)                    # remove top/right spines
fig.savefig("plot.png", dpi=300, bbox_inches="tight")
```

## Do's and Don'ts

### ✅ Do
- Pass tidy (long-form) DataFrames — one row per observation, columns as variables.
- Use figure-level functions (`relplot`/`displot`/`catplot`) for automatic faceting.
- Set the theme once with `sns.set_theme()`; override per-plot as needed.
- Grab the returned `Axes`/`FacetGrid` to tweak titles, limits, and save via matplotlib.

### ❌ Don't
- Don't feed wide data expecting `hue` grouping — melt to long form first (`pd.melt`).
- Don't mix `plt.show()` timing with figure-level functions — they create their own Figure.
- Don't put a figure-level plot inside a pre-made `subplots()` grid — use axes-level for that.
- Don't ignore the `palette` deprecation: newer seaborn wants `hue=` set when using `palette` on bar/box plots.

## Styling, Theming & Customization
- `set_theme(style, palette, font, font_scale, rc)` — one call for the whole session.
- `sns.despine(left=False, bottom=False, trim=True)` cleans spines.
- Element kwargs pass through to matplotlib (`linewidth`, `alpha`, `edgecolor`).
- `FacetGrid.map`/`map_dataframe` to apply custom functions per facet.
- The `seaborn.objects` (`so`) interface exposes a layered grammar: `so.Plot().add().scale().facet().theme()`.

## Advanced Features
- **`seaborn.objects`**: composable grammar-of-graphics with `Dot`, `Line`, `Bar`, `Area`, `Band`, stat transforms (`Agg`, `Est`, `Hist`, `KDE`), and `so.Plot.on(ax)` for embedding.
- **`clustermap`**: hierarchical clustering with row/col dendrograms and color annotations.
- **`jointplot`/`JointGrid`**: bivariate + marginal distributions (`kind="hex"|"kde"|"reg"`).
- **`PairGrid`**: custom upper/lower/diagonal plot functions across variable pairs.
- **Statistical estimation**: automatic bootstrapped CIs on `barplot`/`lineplot`/`pointplot` (`errorbar=("ci",95)` or `("se",1)`).

### How to use the objects (grammar-of-graphics) interface
The `seaborn.objects` API composes layers like ggplot/Plot — the future direction of the library.
```python
import seaborn.objects as so
(
    so.Plot(df, x="flipper_length_mm", y="body_mass_g", color="species")
      .add(so.Dot(alpha=0.6))
      .add(so.Line(), so.PolyFit())          # trend layer via stat transform
      .scale(color="deep")
      .facet(col="island")
      .label(title="Penguins")
      .theme({"axes.grid": True})
)
```
Marks: `Dot`, `Dots`, `Line`, `Lines`, `Path`, `Bar`, `Bars`, `Area`, `Band`, `Range`, `Text`. Stats/moves: `Agg`, `Est`, `Hist`, `KDE`, `PolyFit`, `Count`, `Perc`, `Dodge`, `Jitter`, `Stack`, `Shift`.

## Integration Notes
- **matplotlib**: every axes-level call accepts `ax=`; grab returns to fine-tune, then `fig.savefig(...)`.
- **pandas**: pass DataFrames directly with `data=`, columns by name to `x`/`y`/`hue`.
- **Jupyter**: renders inline like matplotlib; use `sns.set_context("notebook")` for readable sizing.
- **so.Plot.on(ax)** embeds an objects-interface plot into an existing matplotlib figure/subplot.

## Common Pitfalls & Troubleshooting
- Palette warning/no effect → set `hue=` (0.12+ ties `palette` to a hue mapping).
- Overlapping x labels → `plt.xticks(rotation=45)` or `g.set_xticklabels(rotation=45)`.
- Figure-level plot won't fit a subplot → it can't; use the axes-level equivalent.
- Heatmap annotations unreadable → adjust `fmt`, `annot_kws={"size":8}`, or `cmap` contrast.
- Slow with big data → sample; `kdeplot` on huge arrays is expensive.

## Best For / Avoid For
`exploratory-data-analysis`, `statistical-plots`, `correlation-heatmaps`, `distribution-comparison`, `regression-viz`, `attractive-defaults` — choose seaborn.
Avoid for: `heavy-interactivity` (Plotly/Bokeh), `non-pandas-data`, `pixel-perfect-bespoke` (raw matplotlib), `web-embedded-interactive`.

## See Also
- `matplotlib.md` — the layer underneath; use it for fine control
- `ggplot2.md` — R's grammar-of-graphics analog
- `plotly-python.md` / `bokeh.md` — interactive Python options
- `../use-case/data-visualization.md`
