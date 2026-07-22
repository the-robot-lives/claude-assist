# FIM Solutions Overview

This is the index of every FIM ("fill-in-the-middle") media-generation solution available to this skill — a library, DSL, file format, or tool that an LLM can be asked to emit output for, which a downstream renderer, compiler, or runtime then turns into a viewable, playable, or fabricable artifact (SVG, PNG, PDF, audio, an interactive canvas, a static site, a board file, etc).

Solutions are grouped into 8 categories below by shared consumer pattern and output family. Each category has:
- A **concise entry** here — one paragraph, what/how/why, for fast scanning
- A **category page** (`overview/{category}.md`) with a 2-4 sentence blurb per solution and links out
- Per-solution **detail pages** (`overview/{category}/{solution}.md`) with full What/How/Why/Source breakdowns

The underlying solution reference docs this was built from live at `fim/solution/{solution}.md`.

---

## 1. Diagrams — DSL / XML

Text- and XML-based diagramming and UML solutions where the LLM emits a declarative source — a terse DSL, a UML/architecture notation, or a serialized XML model — that a CLI, library, or editor renders to SVG, PNG, or PDF. Spans general-purpose diagramming (Mermaid, PlantUML, Graphviz), C4/software-architecture notations (C4-PlantUML, Structurizr DSL), the blockdiag family of specialized box-diagram tools (activity, network, packet, rack, sequence), interchange/interop formats (XMI, Draw.io XML, BPMN XML), and a commercial high-scale option (yFiles). Pick within this category by output breadth needed (Mermaid/PlantUML for general docs) vs. a specific diagram type (the blockdiag family) vs. interoperability/execution requirements (XMI for tool exchange, BPMN for process engines).

**18 solutions**: Mermaid, PlantUML, C4-PlantUML, Graphviz, Graphviz DOT, nomnoml, Structurizr DSL, XMI, yUML, Draw.io XML, BPMN XML, yFiles, Blockdiag, actdiag, nwdiag, packetdiag, rackdiag, seqdiag

→ [Category page](overview/diagrams-dsl-xml.md)

## 2. Data Visualization

Charting and plotting solutions turning data into charts, graphs, and dashboards across the JavaScript (browser), Python, and Julia/R ecosystems. The LLM emits library-specific code or a declarative spec (a JSON grammar, a DataFrame call chain, a component tree), which a runtime — browser, Python/Julia/R process, or notebook — renders into an interactive or static visual. JS options range from lightweight (Chart.js) to full-featured (ECharts, Highcharts) to grammar-of-graphics (Vega/Vega-Lite, Observable Plot) to low-level (D3.js); Python spans the matplotlib-based static stack (Seaborn, pandas-plotting), interactive/declarative options (Plotly, Altair, Bokeh, HoloViews), full app frameworks (Dash, Streamlit, Panel), and ML-specific diagnostics (scikit-learn viz); Julia/R covers the grammar-of-graphics standards in each language.

**24 solutions**: Apache ECharts, Chart.js, Google Charts, Highcharts, Plotly.js, Vega, Vega-Lite, Observable Plot, D3.js, GoJS, Matplotlib, Seaborn, pandas plotting, Plotly (Python), Altair, Bokeh, HoloViews, scikit-learn Viz, Dash, Streamlit, Panel, Gadfly.jl, Plots.jl, ggplot2

→ [Category page](overview/data-visualization.md)

## 3. Network & Graph Visualization + 3D Engines / WebGL

Two related families of spatial rendering: node-edge graph visualization (force/constraint layouts and network analysis, from lightweight Springy.js to WebGL-scale Sigma.js to desktop-analytics Gephi) and 3D/WebGL rendering engines (general-purpose scene graphs like Three.js/Babylon.js, declarative/framework options like React Three Fiber and A-Frame, and specialized engines for georeferenced globes, scientific volumes, and stylized pseudo-3D). Most emit JavaScript for the browser or Python/Java for an analysis runtime, rendered to an interactive canvas, a plotted image, or a streamed render. Choose within the network half by scale and control tradeoffs (Vis.js quick setup → Sigma.js scale → D3-force/Cola.js custom control → NetworkX/igraph/Gephi for analysis); choose within the 3D half by generality vs. specialization (Three.js/Babylon.js general-purpose vs. Cesium for globes, VTK.js/ParaView Web for scientific data, Zdog for stylized icons).

**21 solutions**: Cytoscape.js, Vis.js Network, Sigma.js, D3 Force, Cola.js, Springy.js, NetworkX, igraph, Gephi, Three.js, Babylon.js, PlayCanvas, React Three Fiber, A-Frame, X3DOM, Verge3D, Zdog, WebGL, Cesium.js, VTK.js, ParaView Web

→ [Category page](overview/network-3d-graphics.md)

## 4. Geospatial & Mapping + Math / Scientific Rendering

Two families sharing an "emit config/expression → downstream runtime renders" pattern: interactive-map and geospatial-analysis tools (browser JS libraries from lightweight Leaflet to WebGL-vector Mapbox/MapLibre to large-scale deck.gl/Kepler.gl, plus Python analysis via Folium/GeoPandas/Turf.js), and math/scientific typesetting or plotting tools (browser math rendering with KaTeX/MathJax, LaTeX-ecosystem publication graphics with TikZ/PGF and Asymptone, interactive graphing via Desmos/GeoGebra/JSXGraph APIs, and Python symbolic math with SymPy/SageMath). Pick within mapping by rendering technology and licensing (Leaflet/MapLibre open vs. Mapbox/Google/HERE commercial, deck.gl/Kepler.gl for scale); pick within math/scientific by whether the deliverable is a typeset document (LaTeX/TikZ/Asymptote), a fast browser render (KaTeX), or an interactive widget (Desmos/GeoGebra/JSXGraph).

**22 solutions**: Leaflet.js, Mapbox GL JS, MapLibre GL JS, OpenLayers, Google Maps API, HERE Maps, deck.gl, Kepler.gl, Folium, GeoPandas, Turf.js, KaTeX, MathJax, LaTeX, TikZ/PGF, Asymptote, MathBox, Desmos API, GeoGebra API, JSXGraph, SymPy, SageMath

→ [Category page](overview/geospatial-math-scientific.md)

## 5. Music Notation + Audio + ML

Three related families: music-notation formats/renderers that turn structured score data into engraved sheet music (interchange formats MusicXML/MEI/MNX/SMuFL; renderers/toolkits VexFlow, OSMD, abcjs, AlphaTab, Music21j; cloud SaaS Flat API and Noteflight API), audio frameworks that synthesize and schedule sound (Tone.js atop the native Web Audio API), and one ML library for creative coding (ml5.js). The LLM emits a structured artifact — notation text/XML/JSON, rendering-API code, or an audio graph — that a downstream engine renders into a visual score, an audible performance, or an interactive canvas. Pick a notation format by interoperability needs (MusicXML default, MEI for scholarly editions, MNX forward-looking), a renderer by input shape (VexFlow programmatic vs. OSMD for existing MusicXML files vs. abcjs for concise ABC text), and audio by control level (Tone.js high-level vs. raw Web Audio API).

**15 solutions**: MusicXML, MEI, MNX, SMuFL, VexFlow, OSMD, abcjs, AlphaTab, Music21j, Flat API, Noteflight API, Tone.js, Web Audio API, ml5.js

→ [Category page](overview/music-audio-ml.md)

## 6. Electronics / HDL / Timing + Image-Video + Document-File Processing

Three distinct sub-domains sharing the "emit spec/code → engine produces artifact" pattern. Electronics/HDL/timing spans LaTeX-embedded schematics (CircuiTikZ), native EDA desktop apps (Fritzing for makers, KiCad for professional fabrication), Python circuit analysis (Lcapy symbolic vs. PySpice numeric simulation), programmatic schematic drawing (SchemDraw), the portable SPICE netlist format, RTL structure visualization (Verilog diagrams), and digital timing/waveform diagrams (WaveDrom rendering the portable WaveJSON format). Image/video processing covers browser WASM video (FFmpeg.wasm) and Node.js image libraries trading portability (Jimp) for native speed (Sharp), plus from-scratch server-side canvas drawing (node-canvas). Document-file processing handles DOCX ingestion (Mammoth.js), PDF consumption (PDF.js) vs. generation (PDFKit server-side, jsPDF browser-side, svg2pdf.js for vector-faithful SVG-to-PDF), and spreadsheet interchange (SheetJS).

**21 solutions**: CircuiTikZ, Fritzing, KiCad, Lcapy, PySpice, SchemDraw, SPICE Netlist, Verilog Diagrams, Digital Timing Diagrams, WaveDrom, WaveJSON, FFmpeg.wasm, Jimp, Sharp, node-canvas, Mammoth.js, PDF.js, PDFKit, jsPDF, SheetJS, svg2pdf.js

→ [Category page](overview/electronics-media-docfile.md)

## 7. Document Authoring & Static-Site Generators + Notebook / Livebook Widgets

Tools for producing written deliverables and interactive notebook output. Document authoring spans lightweight markup (Markdown as the default, AsciiDoc/reStructuredText for richer semantic docs, DocBook/DITA XML standards for enterprise manuals), the static-site generators that compile markup into sites (Hugo for build speed, Jekyll for GitHub Pages, MkDocs/Sphinx for project docs), and format conversion/reproducible-research tooling (Pandoc as the universal converter underlying Quarto and R Markdown, Typst as a fast LaTeX alternative). Notebook/Livebook widgets cover Jupyter's ipywidgets and the full Elixir Kino family — DataTable, VegaLite, Plotly, MapLibre, Mermaid, ETS, Process, and the JS escape hatch — each rendering different data (tables, charts, maps, diagrams, runtime state) inline in a notebook cell.

**23 solutions**: Markdown, AsciiDoc, reStructuredText, DocBook, DITA, Typst, HTML, Hugo, Jekyll, MkDocs, Sphinx, Pandoc, Quarto, R Markdown, ipywidgets, Kino.DataTable, Kino.VegaLite, Kino.Plotly, Kino.MapLibre, Kino.Mermaid, Kino.ETS, Kino.Process, Kino.JS

→ [Category page](overview/document-authoring-notebooks.md)

## 8. 2D Canvas / SVG / Creative Coding + Animation

Solutions that produce and animate 2D graphics for the browser — from the raw Canvas API and vector/creative-coding frameworks (Paper.js, p5.js, Pts.js, Two.js, SVG.js) to a hand-drawn-aesthetic specialist (Rough.js), a print/LaTeX outlier (MetaPost), a no-code 3D outlier (Spline), and dedicated animation/motion engines. The LLM emits JavaScript (or, for MetaPost, a compiled figure language) that draws shapes or animates existing page elements, rendered live in a browser surface (Canvas, SVG DOM, or WebGL) rather than exported as a static file. Choose the drawing half by output flexibility (Two.js renders to SVG/Canvas/WebGL interchangeably) vs. creative-coding conventions (p5.js) vs. raw control (Canvas API); choose animation by weight and scope — GSAP for full-featured commercial-grade timelines, Anime.js for a lighter free middle ground, Velocity.js for jQuery-style UI transitions, Mo.js for burst/particle effects, Lottie for designer-authored After Effects playback.

**15 solutions**: HTML5 Canvas API, Paper.js, p5.js, Processing.js, Pts.js, Rough.js, SVG.js, Two.js, MetaPost, Spline, Anime.js, GSAP, Lottie, Mo.js, Velocity.js

→ [Category page](overview/canvas-svg-creative-animation.md)

---

## Totals

8 categories, 159 solutions, each with a category summary and a per-solution detail page.

| Category | Count | Category page |
|---|---|---|
| Diagrams — DSL / XML | 18 | `overview/diagrams-dsl-xml.md` |
| Data Visualization | 24 | `overview/data-visualization.md` |
| Network & Graph + 3D Engines / WebGL | 21 | `overview/network-3d-graphics.md` |
| Geospatial & Mapping + Math / Scientific | 22 | `overview/geospatial-math-scientific.md` |
| Music Notation + Audio + ML | 15 | `overview/music-audio-ml.md` |
| Electronics / HDL + Image-Video + Doc-File | 21 | `overview/electronics-media-docfile.md` |
| Document Authoring + Notebook Widgets | 23 | `overview/document-authoring-notebooks.md` |
| 2D Canvas / SVG / Creative Coding + Animation | 15 | `overview/canvas-svg-creative-animation.md` |
