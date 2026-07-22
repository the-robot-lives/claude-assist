# Gadfly.jl — Grammar of graphics for Julia

Gadfly is a Julia plotting library modeled on the Grammar of Graphics (like ggplot2 and Vega-Lite). A plot is a data source plus a set of *elements*: **Geometries** (`Geom.*`), **Scales** (`Scale.*`), **Guides** (`Guide.*`, axis labels/legends/titles), **Statistics** (`Stat.*`), **Coordinates** (`Coord.*`), and a **Theme**. It renders crisp SVG (also PNG/PDF/PS via Cairo) and integrates natively with DataFrames.

**Current Version**: Gadfly.jl 1.4.x (current)  **License**: MIT  **Runtime**: Julia 1.6+; SVG (Compose.jl), PNG/PDF/PS via Cairo

## Official Resources & Documentation
- Docs: http://gadflyjl.org/stable/
- Gallery: http://gadflyjl.org/stable/gallery/
- Repo: https://github.com/GiovineItalia/Gadfly.jl

## Installation & Setup
```julia
using Pkg
Pkg.add("Gadfly")
Pkg.add("DataFrames"); Pkg.add("RDatasets")   # common companions
Pkg.add("Cairo"); Pkg.add("Fontconfig")       # for PNG/PDF/PS export
```
```julia
using Gadfly, DataFrames, RDatasets
iris = dataset("datasets", "iris")
```

## Core API — `plot(data, aesthetics..., elements...)`
```julia
plot(iris,
     x = :SepalLength, y = :SepalWidth, color = :Species,   # aesthetic mappings
     Geom.point, Geom.smooth(method = :lm),                  # geometries (layers)
     Guide.xlabel("Sepal Length (cm)"),
     Guide.ylabel("Sepal Width (cm)"),
     Guide.title("Iris"),
     Scale.color_discrete_manual("#4e79a7", "#f28e2b", "#e15759"),
     Theme(default_color = "darkblue", point_size = 3pt))
```
Aesthetics bind DataFrame columns (`x=:col`) or arrays (`x=[...]`). Elements are order-independent positional args.

## Geometries (`Geom.*`)
- **Points/lines**: `Geom.point`, `Geom.line`, `Geom.path`, `Geom.step`, `Geom.smooth` (loess/lm trend), `Geom.abline`, `Geom.hline`, `Geom.vline`.
- **Bars/areas**: `Geom.bar`, `Geom.histogram`, `Geom.histogram2d`, `Geom.density`, `Geom.density2d`, `Geom.ribbon`, `Geom.polygon`.
- **Distributions**: `Geom.boxplot`, `Geom.violin`, `Geom.beeswarm`, `Geom.errorbar`, `Geom.point` + `Geom.errorbar`.
- **Grids/fields**: `Geom.rectbin` (heatmap), `Geom.contour`, `Geom.hexbin`.
- **Labels/annotation**: `Geom.label`, `Geom.annotation`.
- **Faceting**: `Geom.subplot_grid` (small multiples driven by `xgroup`/`ygroup`).

## Scales (`Scale.*`)
```julia
Scale.x_log10, Scale.y_sqrt, Scale.x_continuous(minvalue=0, maxvalue=10)
Scale.color_discrete_manual("red","green","blue")     # categorical palette
Scale.color_continuous(colormap = Scale.lab_gradient("white","steelblue"))
Scale.x_discrete, Scale.y_log2, Scale.color_none
```
Discrete vs continuous scales are auto-chosen from data types; override with the appropriate `Scale.*`.

## Guides (`Guide.*` — axes, legends, decorations)
```julia
Guide.xlabel("X"), Guide.ylabel("Y"), Guide.title("Title"),
Guide.colorkey(title="Group"), Guide.xticks(ticks=[0,2,4,6]),
Guide.annotation(compose(context(), text(1,1,"note"))),
Guide.manual_color_key("Legend", ["A","B"], ["#4e79a7","#e15759"])
```

## Statistics & Coordinates
```julia
# Stats usually applied implicitly by geoms; can be explicit:
Stat.histogram(bincount=20), Stat.density, Stat.qq, Stat.xticks
# Coordinates:
Coord.cartesian(xmin=0, xmax=10, ymin=0, fixed=true)   # aspect/limits
```

## How-To

### How to set colors / palette / theme
Color is an aesthetic mapped through a color Scale; global look is set via `Theme`.
```julia
# 1) Map a column to color (adds a legend)
plot(iris, x=:SepalLength, y=:SepalWidth, color=:Species, Geom.point)

# 2) Explicit discrete palette
plot(df, x=:x, y=:y, color=:cat, Geom.point,
     Scale.color_discrete_manual("#4e79a7", "#f28e2b", "#e15759"))

# 3) Continuous colormap
plot(df, x=:x, y=:y, color=:value, Geom.point,
     Scale.color_continuous(colormap=Scale.lab_gradient("#440154","#21908C","#FDE725")))

# 4) Constant color + full theme
plot(df, x=:x, y=:y, Geom.point,
     Theme(default_color="#4e79a7", background_color="white",
           point_size=3pt, grid_color="gray", major_label_font_size=14pt))

# 5) Set a theme for the whole session
Gadfly.push_theme(Theme(background_color="white", key_position=:bottom))
```
Gadfly's default categorical palette is generated in LCHab color space for good perceptual spacing. Override per-plot with `Scale.color_discrete_manual` or a custom `Scale.color_discrete_hue`.

### How to build faceted small multiples
```julia
plot(iris, x=:PetalLength, y=:PetalWidth,
     color=:Species, xgroup=:Species,
     Geom.subplot_grid(Geom.point))
```
`xgroup`/`ygroup` define the facet dimensions; `Geom.subplot_grid` wraps the inner geoms.

### How to overlay geoms / layers
```julia
plot(iris, x=:SepalLength, y=:SepalWidth,
     layer(Geom.point),
     layer(Geom.smooth(method=:lm), Theme(default_color="red")))
# layer() lets each layer carry its own aesthetics/theme
```

### How to combine boxplot + violin
```julia
plot(iris, x=:Species, y=:SepalLength, Geom.violin, Geom.boxplot)
```

### How to export
```julia
p = plot(iris, x=:SepalLength, y=:SepalWidth, Geom.point)
draw(SVG("plot.svg", 6inch, 4inch), p)
draw(PNG("plot.png", 6inch, 4inch, dpi=300), p)   # needs Cairo + Fontconfig
draw(PDF("plot.pdf", 6inch, 4inch), p)
```

## Do's and Don'ts

### ✅ Do
- Pass a DataFrame and reference columns by `Symbol` (`x=:col`) for clean, labeled plots.
- Use `layer(...)` to overlay geoms that each need distinct aesthetics/themes.
- Install `Cairo`+`Fontconfig` before attempting PNG/PDF export.
- Use `Geom.subplot_grid` with `xgroup`/`ygroup` for faceting.

### ❌ Don't
- Don't expect Plots.jl-level speed on large datasets — Gadfly's SVG/Compose rendering is slower; sample or use `Geom.hexbin`.
- Don't try PNG export without Cairo — SVG is the only backend otherwise.
- Don't mix up `color=` (aesthetic → legend) with `Theme(default_color=...)` (constant, no legend).
- Don't rely on rich interactivity — Gadfly SVGs have only basic hover/zoom, not full dashboards.

## Styling, Theming & Customization
- `Theme(...)` controls fonts (`major_label_font`, `minor_label_font_size`), colors (`default_color`, `background_color`, `grid_color`), point/line sizing (`point_size`, `line_width`), `key_position` (`:right`,`:top`,`:bottom`,`:none`).
- `Gadfly.push_theme` / `pop_theme` / `with_theme` scope themes.
- Units are typed: `pt`, `mm`, `inch`, `cx`/`cy` (Compose measures).

## Advanced Features
- **Compose.jl integration**: annotate with arbitrary vector graphics via `Guide.annotation(compose(...))`.
- **Statistics layer**: `Stat.qq`, `Stat.density`, `Stat.histogram`, `Stat.contour` for statistical transforms.
- **Multiple layers** with independent data/aesthetics via `layer()`.
- **RDatasets**: convenient sample data for prototyping.
- **DataFrames-native**: grouping, faceting, and color keys derive directly from columns.

## Integration Notes
- **Jupyter (IJulia) / Pluto**: SVG plots render inline automatically; no backend selection needed.
- **DataFrames.jl**: reference columns by `Symbol`; grouping/color/faceting derive from columns directly.
- **Compose.jl / Cairo.jl**: SVG is native (Compose); add Cairo + Fontconfig for PNG/PDF/PS raster/print output.
- **Weave.jl / Documenter.jl**: embed Gadfly SVGs in generated reports and docs.

### How to stack plots vertically
```julia
p1 = plot(iris, x=:SepalLength, Geom.histogram)
p2 = plot(iris, x=:SepalLength, y=:SepalWidth, Geom.point)
vstack(p1, p2)          # also hstack, gridstack for grids
```

## Common Pitfalls & Troubleshooting
- PNG/PDF fails → add `Cairo` and `Fontconfig`.
- Slow/hangs on big data → reduce points, use `Geom.hexbin`/`Geom.histogram2d`.
- No legend → color set via `Theme` (constant) instead of `color=` aesthetic.
- Wrong scale type → force with `Scale.x_continuous`/`Scale.x_discrete`.
- Long first plot → Julia JIT compilation latency (normal); subsequent plots are faster.

## Best For / Avoid For
`julia-statistical-graphics`, `grammar-of-graphics`, `publication-svg`, `faceted-analysis`, `ggplot2-familiar-users` — choose Gadfly.
Avoid for: `large-datasets`/`performance-critical` (use Plots.jl/Makie), `heavy-interactivity`, `3D`, `non-julia`.

## See Also
- `plots_jl.md` — Julia's general-purpose, faster plotting meta-package
- `ggplot2.md` — the R grammar-of-graphics Gadfly emulates
- `vega-lite.md` — declarative grammar-of-graphics in JSON
- `../use-case/data-visualization.md`
