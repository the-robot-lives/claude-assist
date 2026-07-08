# ggplot2

## What
ggplot2 is R's implementation of the Grammar of Graphics for declarative statistical visualizations. Part of the tidyverse, it builds plots layer by layer from data, aesthetics, geoms, scales, and themes, producing static graphics by default.

## How
- The LLM emits R: `ggplot(data, aes(x, y, color)) + geom_point() + geom_smooth(method="lm") + scale_...() + labs(...) + theme_minimal()`, adding layers with `+`.
- Rendered by `install.packages("ggplot2")` and evaluating the plot object in R (RStudio, R Markdown, or Shiny).
- Final artifact: static figures exported to PNG, PDF, SVG, or EPS.

## Why
- Reach for ggplot2 for statistical graphics, publication-quality journal/report figures, faceted/composite layouts, and reproducible code-based plotting in the R ecosystem.
- Tradeoffs: R-only, grammar concepts require upfront learning, static by default (use plotly for interactivity), and it can be slow and memory-heavy on very large datasets.
- It is the canonical grammar-of-graphics library that inspired Gadfly.jl (Julia) and Altair/plotnine (Python); within its category it is the R statistical-plotting standard.

## Source
- Solution reference: `fim/solution/ggplot2.md`
