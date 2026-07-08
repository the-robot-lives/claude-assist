# Plots.jl — Julia's unified plotting interface

Plots.jl is Julia's meta-plotting package: one consistent API that dispatches to interchangeable rendering *backends* (GR, PlotlyJS, PythonPlot/Matplotlib, PGFPlotsX, UnicodePlots, …). You write `plot(x, y; attrs...)` once and switch backends with a single function call. Its recipe system lets any Julia type define how it plots, so packages across the ecosystem "just plot."

**Current Version**: Plots.jl 1.40.x (current major)  **License**: MIT  **Runtime**: Julia 1.9+; backend renders (GR is default, fast, static + light interactivity)

## Official Resources & Documentation
- Docs: https://docs.juliaplots.org/stable/
- Attributes: https://docs.juliaplots.org/stable/attributes/
- Backends: https://docs.juliaplots.org/stable/backends/
- GitHub: https://github.com/JuliaPlots/Plots.jl

## Installation & Setup
```julia
using Pkg
Pkg.add("Plots")
# optional backends:
Pkg.add("GR")          # default: fast, static
Pkg.add("PlotlyJS")    # interactive HTML
Pkg.add("PythonPlot")  # matplotlib
Pkg.add("PGFPlotsX")   # LaTeX/TikZ publication output
```
```julia
using Plots
gr()          # select backend: gr(), plotlyjs(), pythonplot(), pgfplotsx(), unicodeplots()
```

## Core API Reference
```julia
x = 0:0.1:2π
plot(x, sin.(x); title="Sine", xlabel="x", ylabel="sin(x)", label="sin", lw=2, color=:steelblue)
plot!(x, cos.(x); label="cos")          # plot! mutates the current plot
p = plot(x, sin.(x))                     # capture a plot object
plot!(p, x, cos.(x))                     # add to a specific plot
scatter(randn(100), randn(100); ms=3, c=:blue, alpha=0.6)
display(p); savefig(p, "out.png")
```
`plot` creates; `plot!` (bang) adds to the current/given plot. Series can be columns of a matrix: `plot(x, [sin.(x) cos.(x)]; label=["sin" "cos"])`.

## Series Types (seriestype / helper functions)
- **Lines/points**: `plot` (`:line`), `scatter` (`:scatter`), `:path`, `:steppre`/`:steppost`, `:sticks`.
- **Bars/areas**: `bar`, `barh`, `:bar`, `histogram`, `histogram2d`, `:stepbins`, `areaplot`, `:line` with `fillrange`.
- **Statistical**: `boxplot`, `violin`, `density`, `histogram`, `dotplot`, `marginalhist`, `corrplot`, `qqplot` (via StatsPlots.jl).
- **Grids/fields**: `heatmap`, `contour`, `contourf`, `surface`, `wireframe`, `quiver`, `spy`.
- **3D**: `plot3d`, `scatter3d`, `surface`, `wireframe` (pass three coordinate args or `zcolor`).
- **Pie/other**: `pie`.
Set explicitly with `plot(...; seriestype=:scatter)`.

## Attributes (the customization surface)
Attributes group into series, subplot/axis, plot, and magic aliases:
```julia
plot(x, y;
  # series
  seriestype=:line, label="A", color=:red, lw=2, ls=:dash, marker=:circle, ms=5, alpha=0.7,
  fillrange=0, fillalpha=0.3,
  # axes / subplot
  title="T", xlabel="x", ylabel="y", xlims=(0,10), ylims=(-1,1),
  xscale=:log10, yscale=:identity, xticks=0:2:10, legend=:topright, grid=true,
  # plot
  size=(700,400), dpi=200, background_color=:white, foreground_color=:black)
```
Common aliases: `c`=color, `lw`=linewidth, `ls`=linestyle, `ms`=markersize, `m`=marker, `st`=seriestype, `lab`=label. Line styles: `:solid`,`:dash`,`:dot`,`:dashdot`. Markers: `:circle`,`:rect`,`:diamond`,`:star5`,`:cross`,`:utriangle`.

## Layouts & Subplots
```julia
p1 = plot(x, sin.(x)); p2 = scatter(randn(50), randn(50))
p3 = histogram(randn(1000)); p4 = bar(["A","B","C"], [1,2,3])
plot(p1, p2, p3, p4; layout=(2,2), size=(800,600))
# grid + relative sizes:
plot(p1, p2, p3; layout=@layout([a; b c]))
# subplot title on a single plot with multiple series regions
plot(rand(10,4); layout=4, legend=false)
```

## How-To

### How to set colors / palette / theme
```julia
# 1) Per-series color (Symbol name, hex string, RGB, or Colorant)
plot(x, y; color=:steelblue)
plot(x, y; color="#4e79a7")
scatter(x, y; zcolor=z, c=:viridis, colorbar=true)   # color by value + colorbar

# 2) Set the series color cycle / palette for a plot
plot(rand(10,3); palette=:tab10)
plot(rand(10,3); color_palette=[:steelblue, :orange, :firebrick])

# 3) Apply a whole theme (fonts, colors, background)
using Plots
theme(:dark)      # :default, :dark, :ggplot2, :juno, :solarized, :wong, :bright, :vibrant
plot(x, y)        # picks up the theme

# 4) Continuous colormap on heatmap/surface
heatmap(matrix; color=:viridis, clims=(0,1))
```
Color gradients: `cgrad(:viridis)`, `cgrad([:blue,:white,:red])`, reverse with `cgrad(:viridis, rev=true)`. Named gradients include `:viridis`, `:plasma`, `:thermal`, `:balance` (diverging), `:blues`.

### How to make a grouped bar / boxplot (StatsPlots)
```julia
using StatsPlots, DataFrames
df = DataFrame(g=repeat(["A","B"], inner=50), v=randn(100))
@df df boxplot(:g, :v)                       # macro binds DataFrame columns
groupedbar(rand(5,3); bar_position=:stack, labels=["x" "y" "z"])
```

### How to build an animation
```julia
anim = @animate for i in 1:100
    plot(x, sin.(x .+ i/10); ylims=(-1,1))
end
gif(anim, "wave.gif", fps=20)               # or mp4(anim, "wave.mp4")
```

### How to export
```julia
savefig(p, "plot.png")     # backend-dependent formats
savefig(p, "plot.pdf")     # vector (GR, PGFPlotsX)
savefig(p, "plot.svg")
savefig(p, "plot.html")    # interactive (PlotlyJS backend)
```

## Do's and Don'ts

### ✅ Do
- Pick the backend for the job: `gr()` for speed/static, `plotlyjs()` for interactive HTML, `pgfplotsx()` for LaTeX-quality print.
- Use `plot!` to layer series onto an existing plot rather than rebuilding.
- Use `theme(...)` for consistent styling across a session/notebook.
- Warm up once — the first plot triggers JIT compilation ("time to first plot"); subsequent plots are fast.

### ❌ Don't
- Don't expect identical output across backends — some attributes are unsupported by certain backends.
- Don't benchmark the first plot call — it includes compilation latency.
- Don't forget matrix-column semantics: `plot(x, [a b])` makes two series; `[a, b]` (comma) is one vector.
- Don't use interactive-only attributes (hover) with the GR backend.

## Styling, Theming & Customization
- `theme(:name)` sets a global look; `Plots.showtheme(:name)` previews.
- Fonts: `guidefontsize`, `tickfontsize`, `legendfontsize`, `titlefontsize`, `fontfamily`.
- Backgrounds: `background_color`, `background_color_inside`, `foreground_color`.
- Grid/ticks: `grid=true`, `gridalpha`, `minorgrid`, `tick_direction=:out`.
- Legends: `legend=:topright | :outertop | false`, `legendtitle`.

## Advanced Features
- **Recipes**: `@recipe`, `@userplot`, `@series` let any type define plotting; StatsPlots, GraphRecipes, and many domain packages ship recipes.
- **StatsPlots.jl**: `@df` DataFrame macro, `corrplot`, `marginalhist`, `density`, `dotplot`, distribution plotting.
- **GraphRecipes.jl**: network/graph layouts.
- **Backends**: UnicodePlots (terminal), InspectDR, Gaston, PGFPlotsX (TikZ), PythonPlot (matplotlib).
- **Animations**: `@animate`, `@gif`, `gif`/`mp4` output.

## Integration Notes
- **Pluto.jl / Jupyter (IJulia)**: plots render inline; `gr()` is fine for notebooks, `plotlyjs()` for interactivity.
- **DataFrames**: use StatsPlots' `@df df plot(:x, :y)` macro to bind columns; Plots also accepts vectors directly.
- **Makie.jl** is the higher-performance alternative for large/GPU/interactive/3D — consider it when Plots.jl is too slow.
- **PackageCompiler.jl**: bake a sysimage to eliminate "time to first plot" in production/CLI tools.
- **LaTeX documents**: `pgfplotsx()` backend emits native TikZ for seamless journal figures.

### How to annotate and add reference lines
```julia
p = plot(x, y)
hline!(p, [0]; ls=:dash, c=:gray, label="")          # horizontal reference
vline!(p, [π]; ls=:dot, c=:red, label="")
annotate!(p, π, 0.5, text("peak", :left, 8))
```

## Common Pitfalls & Troubleshooting
- Slow first plot → normal JIT compilation; use a sysimage (PackageCompiler) to cut latency.
- Attribute ignored → unsupported by current backend; try another backend or check the attribute page.
- Interactive features missing → switch to `plotlyjs()`.
- Comma vs space in arrays → `[a b]` = two series (hcat), `[a, b]` = one concatenated series.
- Fonts/LaTeX not rendering → use `pgfplotsx()` for full LaTeX text.

## Best For / Avoid For
`julia-scientific-computing`, `backend-flexible-plots`, `exploratory-viz`, `animations`, `publication-latex` (via PGFPlotsX), `recipe-driven-package-plots` — choose Plots.jl.
Avoid for: `non-julia`, `low-latency-first-call-critical` (without sysimage), `advanced-grammar-of-graphics` (use Gadfly/Makie), `heavy-web-interactivity`.

## See Also
- `gadfly_jl.md` — grammar-of-graphics alternative in Julia
- `matplotlib.md` — the PythonPlot backend's engine
- `plotly-python.md` — PlotlyJS backend relative
- `../use-case/data-visualization.md`
