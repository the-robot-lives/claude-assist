# ggplot2 — R's grammar of graphics

ggplot2 is R's implementation of the Grammar of Graphics: you build a plot by adding layers with `+`. Every plot combines **data**, **aesthetic mappings** (`aes()`, columns → visual channels), **geoms** (geometric layers), **scales**, **facets**, **stats**, **coordinates**, and a **theme**. Part of the tidyverse, it produces publication-quality static graphics and is the reference implementation others (Vega-Lite, plotnine, ggplot-style libs) emulate.

**Current Version**: ggplot2 3.5.x (current major)  **License**: MIT  **Runtime**: R 3.5+; static output (PNG/PDF/SVG/EPS), interactive via `plotly::ggplotly` or `ggiraph`

## Official Resources & Documentation
- Docs: https://ggplot2.tidyverse.org/
- Reference: https://ggplot2.tidyverse.org/reference/
- Book (free): https://ggplot2-book.org/
- Cheatsheet: https://rstudio.github.io/cheatsheets/data-visualization.pdf

## Installation & Setup
```r
install.packages("ggplot2")     # or install.packages("tidyverse")
library(ggplot2)
```

## Core Grammar — the layered call
```r
ggplot(data = mtcars, aes(x = wt, y = mpg, color = factor(cyl))) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = FALSE) +
  scale_color_brewer(palette = "Set1") +
  labs(title = "Weight vs MPG", x = "Weight (1000 lbs)", y = "MPG", color = "Cylinders") +
  facet_wrap(~ gear) +
  theme_minimal()
```
`ggplot(data, aes(...))` sets defaults; each `geom_*()` adds a layer. Aesthetics inside `aes()` map to data columns; outside `aes()` they are constants (`geom_point(color = "red")`).

## Geoms (geometric layers)
- **Points/lines**: `geom_point`, `geom_line`, `geom_path`, `geom_step`, `geom_jitter`, `geom_smooth` (trend + CI).
- **Bars/areas**: `geom_bar` (counts), `geom_col` (values), `geom_histogram`, `geom_area`, `geom_ribbon`, `geom_freqpoly`.
- **Distributions**: `geom_boxplot`, `geom_violin`, `geom_density`, `geom_dotplot`, `geom_density_2d`, `geom_hex`, `geom_bin2d`.
- **Text/annotation**: `geom_text`, `geom_label`, `annotate`, `geom_hline`/`geom_vline`/`geom_abline`, `geom_segment`, `geom_rect`.
- **Categorical/2D fields**: `geom_tile` (heatmap), `geom_raster`, `geom_contour`.
- **Error/interval**: `geom_errorbar`, `geom_pointrange`, `geom_crossbar`, `geom_linerange`.
- **Maps**: `geom_sf` (simple features), `geom_polygon`, `geom_map`.

## Aesthetic Mappings (`aes`)
Channels: `x`, `y`, `color`/`colour` (points/lines), `fill` (areas/bars), `alpha`, `size`, `shape`, `linetype`, `group`, `label`, `weight`. Map columns: `aes(x = wt, y = mpg, color = cyl, size = hp)`. Use `group` to control which rows connect/aggregate together.

## Scales
Scales control how data maps to aesthetics and define axes/legends.
```r
+ scale_x_continuous(limits = c(0,10), breaks = seq(0,10,2), labels = scales::dollar)
+ scale_x_log10() + scale_y_sqrt()
+ scale_x_date(date_labels = "%b %Y")
+ scale_color_manual(values = c("4" = "#4e79a7", "6" = "#f28e2b", "8" = "#e15759"))
+ scale_fill_gradient(low = "white", high = "steelblue")
+ scale_fill_viridis_c()          # continuous viridis
+ scale_color_brewer(palette = "Set2")   # discrete ColorBrewer
```

## Facets (small multiples)
```r
+ facet_wrap(~ variable, ncol = 3, scales = "free_y")
+ facet_grid(rows = vars(drv), cols = vars(cyl))
```

## Stats & Coordinates
```r
+ stat_summary(fun = mean, geom = "point")     # explicit stat layer
+ coord_flip()                                  # swap x/y (horizontal bars)
+ coord_polar()                                 # pie / radial
+ coord_cartesian(xlim = c(0,5))                # zoom without dropping data
+ coord_fixed(ratio = 1)                        # equal aspect
```

## How-To

### How to set colors / palette / theme
Color mapping vs manual color vs global theme are distinct.
```r
# 1) Map a column to color/fill (adds a legend)
ggplot(df, aes(x, y, color = category)) + geom_point()

# 2) Constant color (outside aes)
ggplot(df, aes(x, y)) + geom_point(color = "#4e79a7")

# 3) Discrete palette
+ scale_color_brewer(palette = "Dark2")        # ColorBrewer
+ scale_color_manual(values = c("#4e79a7","#f28e2b","#e15759"))
+ scale_fill_viridis_d()                        # viridis discrete

# 4) Continuous palette
+ scale_fill_gradient2(low="blue", mid="white", high="red", midpoint=0)  # diverging
+ scale_color_viridis_c(option = "magma")

# 5) Whole-plot theme
+ theme_minimal(base_size = 13)                 # theme_gray/bw/classic/void/light/dark
# global default for the session:
theme_set(theme_minimal())
# fine-tune any element:
+ theme(legend.position = "bottom",
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 16),
        axis.text.x = element_text(angle = 45, hjust = 1))
```
Palettes: ColorBrewer (`scale_*_brewer`, `distiller`), viridis (`_viridis_d/_c`), manual, `scale_*_gradient/gradient2/gradientn`. The `paletteer` package exposes hundreds more.

### How to make a grouped/stacked bar
```r
ggplot(df, aes(x = month, y = sales, fill = product)) +
  geom_col(position = "stack")        # "dodge" for grouped, "fill" for 100%
```

### How to plot a correlation-style heatmap
```r
ggplot(long_df, aes(x = var1, y = var2, fill = corr)) +
  geom_tile() +
  scale_fill_gradient2(low="#4575b4", mid="white", high="#d73027", midpoint=0, limits=c(-1,1)) +
  geom_text(aes(label = round(corr, 2)), size = 3) +
  theme_minimal()
```

### How to save a figure
```r
ggsave("plot.png", width = 8, height = 5, dpi = 300)          # last plot
ggsave("plot.pdf", plot = p, width = 8, height = 5)           # vector
ggsave("plot.svg", plot = p)
```

### How to make it interactive
```r
library(plotly);  ggplotly(p)          # convert a ggplot to interactive
# or library(ggiraph) with geom_*_interactive() layers
```

## Do's and Don'ts

### ✅ Do
- Feed tidy/long data (one observation per row); reshape with `tidyr::pivot_longer`.
- Put data-driven color/size/shape *inside* `aes()`, constants *outside*.
- Use `geom_col` for pre-computed values and `geom_bar` for raw counts.
- Set a house style once with `theme_set()` / `update_geom_defaults()`.

### ❌ Don't
- Don't confuse `color` (outlines/points) with `fill` (area interiors) — bars/boxes need `fill`.
- Don't use `coord_cartesian(ylim=...)` vs `scale_y_continuous(limits=...)` interchangeably — the latter drops data outside range and can break stats.
- Don't rely on default `geom_bar` when you have y-values — it will try to count.
- Don't render huge point clouds without `geom_hex`/`geom_bin2d` or alpha — overplotting hides structure.

## Styling, Theming & Customization
- Built-in themes: `theme_gray` (default), `theme_bw`, `theme_minimal`, `theme_classic`, `theme_void`, `theme_light`, `theme_dark`.
- `theme()` overrides any `element_text`/`element_line`/`element_rect`/`element_blank`.
- Labels via `labs()`, `xlab()`, `ylab()`, `ggtitle()`.
- Extension themes: `ggthemes` (economist, fivethirtyeight, tufte), `hrbrthemes`.
- `guides()` fine-tunes legends; `guide_legend`/`guide_colorbar`.

## Advanced Features
- **Extensions**: `patchwork` (compose plots with `p1 + p2 / p3`), `gganimate` (animation), `ggrepel` (non-overlapping labels), `ggiraph`/`plotly` (interactivity), `sf`/`ggspatial` (maps), `GGally` (pairs/matrices).
- **Stats**: every geom has a default stat; `stat_summary`, `stat_bin`, `stat_density`, `stat_ecdf`.
- **Positions**: `position_dodge`, `position_stack`, `position_fill`, `position_jitter`, `position_nudge`.
- **Custom scales/annotations**: `annotate()`, secondary axes via `sec_axis()`.

## Integration Notes
- **R Markdown / Quarto**: plots render inline; control size with chunk options `fig.width`, `fig.height`, `dpi`.
- **Shiny**: `renderPlot({ ggplot(...) })` + `plotOutput("id")` for reactive dashboards; `ggplotly()` for interactivity.
- **patchwork**: compose multiple ggplots with operators — `(p1 | p2) / p3`, `p1 + plot_annotation(title=...)`.
- **tidyverse**: pipe data in — `df |> filter(...) |> ggplot(aes(...)) + ...`.
- **Export at scale**: `ggsave` respects `units=("in"|"cm"|"mm")` and `device=cairo_pdf` for embedded fonts.

### How to compose and annotate multi-panel figures
```r
library(patchwork)
(p1 + p2) / p3 +
  plot_annotation(title = "Dashboard", tag_levels = "A") &
  theme_minimal()
```

## Common Pitfalls & Troubleshooting
- "stat_count() must not be used with a y aesthetic" → use `geom_col()` (or `stat="identity"`).
- Legend not appearing → the aesthetic is set outside `aes()` (constant), so no mapping/legend.
- Colors not applying → wrong scale (`color` vs `fill`) for the geom.
- Overlapping labels → `ggrepel::geom_text_repel`.
- Facets share axes unexpectedly → set `scales = "free"`/`"free_y"`.

## Best For / Avoid For
`statistical-graphics`, `publication-figures`, `exploratory-analysis`, `faceted-comparisons`, `reproducible-research`, `r-markdown-reports` — choose ggplot2.
Avoid for: `non-R`, `native-interactivity` (use plotly/ggiraph), `very-large-data` (downsample/hexbin), `3D`.

## See Also
- `seaborn.md` — Python's closest statistical analog
- `vega-lite.md` / `gadfly_jl.md` — other grammar-of-graphics implementations
- `plots_jl.md` — Julia general plotting
- `../use-case/data-visualization.md`
