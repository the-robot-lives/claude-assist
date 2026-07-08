# Gadfly.jl

## What
Gadfly.jl is a statistical plotting library for Julia based on the Grammar of Graphics, offering ggplot2-like syntax. It emphasizes layered, composable statistical plots with fine-grained control and vector output.

## How
- The LLM emits Julia: `plot(df, x=:col, y=:col, color=:cat, Geom.point, Geom.smooth, Guide.xlabel(...), Theme(...))`, composing geometries, guides, scales, and themes; supports faceting via `Geom.subplot_grid`.
- Rendered by `Pkg.add("Gadfly")` (typically with `DataFrames`, `RDatasets`); plots display in notebooks/IDE.
- Final artifact: SVG, PNG, or PDF statistical plots.

## Why
- Reach for Gadfly for publication-quality static statistical plots and layered exploratory analysis in Julia, especially if you already know ggplot2's grammar.
- Tradeoffs: slower rendering than Plots.jl on large datasets, less active development and a smaller community, limited interactive features, a grammar-of-graphics learning curve, and it can be memory-intensive.
- Versus Plots.jl it is the grammar-of-graphics / statistical specialist rather than the general-purpose multi-backend workhorse.

## Source
- Solution reference: `fim/solution/gadfly_jl.md`
