# Data Visualization

Charting and plotting solutions that turn data into charts, graphs, and dashboards across the JavaScript (browser), Python, and Julia/R ecosystems. The shared pattern: the LLM emits library-specific code or a declarative spec, which a runtime (a browser, a Python/Julia/R process, or a notebook) renders into an interactive or static visual artifact.

## Solutions

### JavaScript / Browser Charting

#### Apache ECharts
Open-source JS charting library with dual Canvas/SVG engines and 20+ chart types (heatmaps, treemaps, sankey, geo maps). Emit an `option` config, `chart.setOption(option)` on an initialized instance. Pick it for breadth and large-dataset performance in one fully open-source library. [Detail](data-visualization/apache-echarts.md)

#### Chart.js
Simple, lightweight (~60KB) Canvas charting with 8 basic types and good defaults. Emit `new Chart(ctx, {...})` on a `<canvas>`. Pick it for quick, responsive dashboards and prototypes where simplicity beats breadth. [Detail](data-visualization/chart_js.md)

#### Google Charts
Free browser charts with Google Sheets integration, GeoCharts, and timeline/Gantt types. Build a `DataTable`, then `chart.draw(data, options)` after loading the gstatic loader. Pick it for Sheets-backed data, maps, and timelines at zero cost. [Detail](data-visualization/google-charts.md)

#### Highcharts
Commercial-grade interactive charts with stock/financial charts, technical indicators, and built-in PDF/SVG/PNG export. Emit `Highcharts.chart('container', {...})`. Pick it for financial dashboards and very large datasets (Boost) when a commercial license is acceptable. [Detail](data-visualization/highcharts.md)

#### Plotly.js
High-level library with 100+ types, built-in 3D, and WebGL rendering, interactive by default. Emit `data` traces + `layout` to `Plotly.newPlot('div', ...)`. Pick it for scientific, statistical, and 3D charts out of the box. [Detail](data-visualization/plotly_js.md)

#### Vega
Declarative visualization grammar — a full JSON spec of data/scales/marks. Parse and render via `new vega.View(vega.parse(spec))`. Pick it for reproducible, JSON-driven graphics in data pipelines and automated reporting. [Detail](data-visualization/vega.md)

#### Vega-Lite
Concise JSON grammar (`mark` + `encoding`) that compiles to Vega, with built-in statistical transforms. Render via `vegaEmbed('#vis', spec)`. Pick it over Vega for terse authoring of statistical charts and dashboards. [Detail](data-visualization/vega-lite.md)

#### Observable Plot
Grammar-of-graphics library from the D3 team, emitting SVG with intelligent defaults. Compose marks in `Plot.plot({...})`. Pick it to cut D3 boilerplate dramatically for exploratory charts while staying in idiomatic JS. [Detail](data-visualization/observable-plot.md)

#### D3.js
Industry-standard low-level library binding data to the DOM (scales, axes, transitions, force/geo/hierarchical layouts). Pick it for maximum control and fully bespoke visualizations that higher-level libraries can't express — at the cost of the steepest learning curve. [Detail](data-visualization/d3_js.md)

#### GoJS
Commercial library for interactive diagrams, flowcharts, and graphs — template-driven with undo/redo. Define node/link templates and a `GraphLinksModel`. Pick it for enterprise diagramming (BPMN, org charts) rather than statistical charts. [Detail](data-visualization/go_js.md)

### Python

#### Matplotlib
The foundational Python plotting library for publication-quality static figures. Emit `pyplot` calls; display with `plt.show()`, export with `savefig`. Pick it for low-level control and as the substrate most other Python viz builds on. [Detail](data-visualization/matplotlib.md)

#### Seaborn
Statistical visualization layer over matplotlib with attractive defaults. Emit `sns.*` calls over a DataFrame. Pick it over raw matplotlib for statistical plots (distributions, heatmaps, regression) with less code. [Detail](data-visualization/seaborn.md)

#### pandas plotting
The built-in `.plot()` accessor on DataFrames/Series, layered on matplotlib. Emit `df.plot(...)`. Pick it for the fastest path from a DataFrame to a chart during EDA. [Detail](data-visualization/pandas-plotting.md)

#### Plotly (Python)
Interactive, web-output plotting with Express and Graph Objects APIs, built-in 3D and maps. Emit `px.*`/`go.Figure`, `fig.show()`, export HTML/PNG. Pick it for interactive, shareable web charts (and it powers Dash). [Detail](data-visualization/plotly-python.md)

#### Altair
Declarative statistical viz that compiles Python to Vega-Lite JSON. Emit `alt.Chart(data).mark_*().encode(...)`. Pick it for grammar-of-graphics EDA with native interactivity and portable specs. [Detail](data-visualization/altair.md)

#### Bokeh
Interactive browser-targeted Python plots with widgets, streaming, and server apps. Emit `bokeh.plotting` code; `show(p)` or `output_file`. Pick it for interactive Python plots and server-driven apps (it underpins HoloViews/Panel). [Detail](data-visualization/bokeh.md)

#### HoloViews
Declarative "annotate data, get plots" library abstracting over Bokeh/Matplotlib/Plotly backends. Compose elements with `*` and `+`. Pick it for minimal, backend-swappable plotting that scales to big data via Datashader. [Detail](data-visualization/holoviews.md)

#### scikit-learn Visualization
ML-specific diagnostic plots (confusion matrix, ROC, decision boundaries, PCA/t-SNE) on matplotlib. Emit Display classes like `ConfusionMatrixDisplay.from_estimator`. Pick it for model evaluation, not general charting. [Detail](data-visualization/sklearn-viz.md)

#### Dash
Reactive Python web-app framework with a React frontend, wiring components to Plotly figures via callbacks. Run `app.run_server()`. Pick it for production dashboards with complex interactions and no hand-written JS. [Detail](data-visualization/dash.md)

#### Streamlit
Script-to-app framework with automatic reactivity and simple deployment. Emit an `st.*` script; run `streamlit run app.py`. Pick it for rapid data-app prototyping without callback wiring. [Detail](data-visualization/streamlit.md)

#### Panel
HoloViz multi-backend dashboard framework on Bokeh, plugging into the whole scientific-Python stack. Pick it over Streamlit/Dash when you need backend-agnostic composition and tight HoloViz integration with production features. [Detail](data-visualization/panel.md)

### Julia / R

#### Gadfly.jl
Grammar-of-graphics statistical plotting for Julia with ggplot2-like syntax and SVG/PNG/PDF output. Emit `plot(df, x=..., Geom.*, ...)`. Pick it for publication-quality static statistical plots in Julia. [Detail](data-visualization/gadfly_jl.md)

#### Plots.jl
Julia's unified plotting interface over multiple backends (GR, PlotlyJS, PyPlot) with one API. Emit `plot()`/`scatter()`/`histogram()`. Pick it as the general-purpose Julia workhorse where backend flexibility matters. [Detail](data-visualization/plots_jl.md)

#### ggplot2
R's grammar-of-graphics standard (tidyverse), building plots layer by layer to static PNG/PDF/SVG/EPS. Emit `ggplot(data, aes(...)) + geom_*() + ...`. Pick it for statistical graphics and publication figures in R. [Detail](data-visualization/ggplot2.md)
