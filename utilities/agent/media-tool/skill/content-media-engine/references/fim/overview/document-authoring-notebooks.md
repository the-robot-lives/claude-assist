# Document Authoring & Static-Site Generators + Notebook / Livebook Widgets

This category covers the tools for producing written deliverables and interactive notebook output: markup document formats (Markdown, AsciiDoc, DocBook, XML standards), the static-site generators and publishing toolchains that compile them, and the inline widgets that render tables, charts, and runtime introspection inside Jupyter and Elixir LiveBook. The shared consumer pattern is that the LLM emits source text (markup, a build config, or notebook cell code) which a processor, CLI, or notebook runtime renders into a final artifact — HTML, PDF, a static site, or a live widget.

## Solutions

### Document Authoring & SSG

### Markdown
Lightweight, source-readable markup (GFM, MDX, CommonMark, MultiMarkdown) using `#` headings, `**bold**`, lists, and fenced code. Rendered by marked.js/markdown-it/Remark/Pandoc, most often to HTML. The default for READMEs, wikis, and blogs, and the content layer feeding most static-site generators — reach for it until you outgrow its structural limits. [Detail](document-authoring-notebooks/markdown.md)

### AsciiDoc
Text format for technical docs, articles, and books with rich semantic features (tables, footnotes, bibliographies, admonitions, includes). Processed by Asciidoctor to HTML, PDF, DocBook, or EPUB. Pick it over Markdown when you need complex tables, cross-references, and modular book-length authoring; lighter than DocBook for the same multi-output goal. [Detail](document-authoring-notebooks/asciidoc.md)

### reStructuredText
Extensible Docutils markup (`.rst`) with underlined titles, `.. code-block::` directives, and `:ref:`/`:doc:` cross-reference roles. Rendered by Docutils or Sphinx. The Python-ecosystem standard — choose it for API docs needing rich cross-references and semantic depth, accepting a steeper, indentation-sensitive syntax versus Markdown. [Detail](document-authoring-notebooks/restructuredtext.md)

### DocBook
XML schema (OASIS) for large technical manuals with `<book>`/`<chapter>`/`<section>` structure. Rendered via XSLT stylesheets (`xsltproc`, `fop`) to HTML, PDF, EPUB, or man pages. Reach for it for narrative book/manual publishing with strict schema validation and established XML workflows; favors narrative structure over DITA's topic-typed reuse. [Detail](document-authoring-notebooks/docbook.md)

### DITA
XML OASIS standard organizing content into typed topics (Concept, Task, Reference) assembled by maps, rendered by the DITA Open Toolkit to PDF/HTML5/EPUB/Word. Pick it for enterprise-scale docs needing strong single-source reuse (conref/keyref), conditional processing, and localization across multi-product suites. [Detail](document-authoring-notebooks/dita.md)

### Typst
Modern markup-based typesetting system (`.typ`) positioned as a LaTeX alternative, with backslash-free syntax and a built-in scripting language. Compiled by the `typst` CLI to PDF (or PNG) with 10-100x faster builds. Choose it for academic papers, theses, and math-heavy documents wanting LaTeX-quality output with live preview and clear errors. [Detail](document-authoring-notebooks/typst.md)

### HTML
Semantic HTML5 markup (`article`/`section`/`nav`/`figure`) rendered directly by any browser, styled with CSS and made interactive with JavaScript. The common render target that Markdown, SSGs, Sphinx, and Pandoc all compile down to — author it directly when you want full markup control, native multimedia, and built-in ARIA accessibility. [Detail](document-authoring-notebooks/html.md)

### Hugo
Fast Go static-site generator that transforms Markdown plus Go-template layouts into a static HTML site via the `hugo` CLI. Reach for it when build speed matters (thousands of pages in seconds), or you need built-in i18n and an asset pipeline; single-binary speed versus Jekyll's Ruby plugin maturity. [Detail](document-authoring-notebooks/hugo.md)

### Jekyll
Ruby static-site generator with first-class GitHub Pages integration, turning Markdown/Liquid templates and YAML front matter into static sites. Built with the `jekyll` CLI and deployable to GitHub Pages without CI/CD. Choose it for zero-config Pages hosting, blog structure, and a mature plugin ecosystem, trading Hugo's raw build speed. [Detail](document-authoring-notebooks/jekyll.md)

### MkDocs
Python static-site generator built specifically for project documentation, turning Markdown plus a `mkdocs.yml` config into a themed (Material) docs site with client-side search. Built via the `mkdocs` CLI. Pick it for a professional Markdown-only docs site with minimal YAML; simpler and Markdown-first versus Sphinx. [Detail](document-authoring-notebooks/mkdocs.md)

### Sphinx
Documentation generator that builds from reStructuredText plus a `conf.py`, with autodoc docstring extraction, intersphinx cross-linking, and HTML/PDF/ePub/LaTeX output. The Python-docs standard — reach for it for comprehensive API reference and library docs where autodoc and rich cross-referencing matter, versus MkDocs' simpler Markdown approach. [Detail](document-authoring-notebooks/sphinx.md)

### Pandoc
Universal document converter (40+ formats) driven by the `pandoc` CLI rather than a markup language of its own, with academic citation/cross-reference support. Emits the requested target (PDF, HTML, DOCX, EPUB). The conversion engine under Quarto and many Markdown/AsciiDoc pipelines — reach for it when the goal is transforming between formats, not authoring a site. [Detail](document-authoring-notebooks/pandoc.md)

### Quarto
Scientific publishing system built on Pandoc that renders `.qmd` documents with executable Python/R/Julia/Observable code fences to dozens of formats (HTML, PDF, Word, slides, books). Choose it for reproducible research and multi-language, multi-format publishing with citations and interactive widgets; the multi-language successor to R Markdown. [Detail](document-authoring-notebooks/quarto.md)

### R Markdown
Combines R code chunks with Markdown (`.rmd`) via knitr and pandoc to produce reproducible reports (HTML, PDF, Word, Shiny). Rendered through the `rmarkdown` package, typically from RStudio. Reach for it for R-centric statistical reports where code and results live in one document; Quarto generalizes the same model beyond R. [Detail](document-authoring-notebooks/r-markdown.md)

### Notebook / Livebook Widgets

### ipywidgets
Interactive widgets for Jupyter/JupyterLab — sliders, dropdowns, pickers, and layout containers — with two-way Python↔JavaScript binding, emitted as Python widget constructors and `@interact` decorators and rendered inline by executing cells. The Jupyter-ecosystem analogue to the Kino widgets; reach for it when the notebook runtime is Python. [Detail](document-authoring-notebooks/ipywidgets.md)

### Kino.DataTable
Core Kino component rendering tabular data as interactive HTML tables (sort/filter/paginate) inside Elixir LiveBook, via `Kino.DataTable.new(data)` with zero extra dependencies. The tabular-data viewer of the Kino family — reach for it for quick data exploration; pair with Kino.VegaLite/Plotly when you need charts. [Detail](document-authoring-notebooks/kino-datatable.md)

### Kino.VegaLite
The Elixir LiveBook binding to Vega-Lite, building declarative chart specs (`VegaLite.new |> mark |> encode_field`) rendered interactively in cells, with `Kino.animate` for streaming. The declarative statistical-charting member of the Kino family — choose it for data exploration and reports; Kino.Plotly covers 3D/scientific plotting. [Detail](document-authoring-notebooks/kino-vegalite.md)

### Kino.Plotly
Brings Plotly.js charts (including 3D surface/scatter3d/mesh) into Elixir LiveBook via `data`/`layout` maps passed to `Kino.Plotly.new`. The scientific/3D charting option of the Kino family — reach for it for interactive rotation/zoom/hover and the Plotly.js feature set, where Kino.VegaLite handles declarative statistical charts. [Detail](document-authoring-notebooks/kino-plotly.md)

### Kino.MapLibre
Embeds interactive MapLibre GL vector maps in Elixir LiveBook via `MapLibre.new |> add_source |> add_layer`, rendering pan/zoom/tilt maps with GeoJSON/vector-tile layers. The geospatial member of the Kino family — choose it for location intelligence and map-story prototyping in notebooks (needs a tile server for base maps). [Detail](document-authoring-notebooks/kino-maplibre.md)

### Kino.Mermaid
Renders Mermaid diagrams (flowcharts, sequence diagrams) inside Elixir LiveBook via `Kino.Mermaid.new(definition)`, producing SVG in cell output with pure-Elixir integration (no JavaScript). The diagramming member of the Kino family — reach for it for visual documentation using familiar Mermaid syntax, accepting static (non-interactive) output. [Detail](document-authoring-notebooks/kino-mermaid.md)

### Kino.ETS
Core Kino component giving real-time visualization of ETS tables (contents, metadata, statistics) in Elixir LiveBook via `Kino.ETS.new(table)` with optional live `refresh`. The ETS-inspection member of the Kino family — reach for it to debug cache/state tables during development, complementing Kino.Process for runtime introspection. [Detail](document-authoring-notebooks/kino-ets.md)

### Kino.Process
Real-time Erlang/Elixir process and supervision-tree visualization for LiveBook via `Kino.Process.app_tree`/`sup_tree`/`info`, rendering interactive trees and info panels. The runtime/OTP-introspection member of the Kino family — choose it to debug OTP systems and teach supervision, complementing Kino.ETS for storage-table inspection. [Detail](document-authoring-notebooks/kino-process.md)

### Kino.JS
The low-level escape hatch of the Kino family: define fully custom LiveBook widgets with your own HTML `content`, `js`, and `css` plus two-way Elixir↔JavaScript communication via `Kino.JS.new`. Reach for it when the built-in Kino widgets aren't enough and you need bespoke visualizations or specialized controls, accepting that it requires JavaScript and manual setup. [Detail](document-authoring-notebooks/kino-js.md)
