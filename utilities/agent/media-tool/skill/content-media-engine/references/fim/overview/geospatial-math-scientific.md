# Geospatial & Mapping + Math / Scientific Rendering

This category groups two related families of FIM solutions: tools that render interactive maps and perform geospatial analysis, and tools that typeset or plot mathematics and scientific figures. The common pattern is that the LLM emits a library init/config script, DSL, or symbolic expression, which a downstream consumer — browser JavaScript, a Python runtime, or a LaTeX/compiler toolchain — turns into an interactive view, computed result, or publication-quality artifact.

## Solutions

#### Geospatial & Mapping

### Leaflet.js
Lightweight (~39–42KB) JS library for interactive raster-tile maps; emit `L.map(...)` init plus tile layers and markers, rendered in the browser from CDN/npm. Pick it for small-footprint, mobile-friendly maps with a huge plugin ecosystem and any tile provider, when you don't need vector-tile/3D performance. [Detail](geospatial-math-scientific/leaflet_js.md)

### Mapbox GL JS
Vector-tile mapping library with WebGL rendering; emit `new mapboxgl.Map(...)` with a style URL and token, rendered GPU-side in the browser. Pick it for smooth continuous zoom, deep style customization, and 3D terrain/buildings in a polished commercial app — at the cost of a token and usage billing. [Detail](geospatial-math-scientific/mapbox-gl-js.md)

### MapLibre GL JS
Open-source, no-token fork of Mapbox GL JS; emit `new maplibregl.Map(...)` against a self-hosted or third-party style/vector tiles. Pick it when you want Mapbox-GL-class WebGL vector rendering on an open, self-hostable stack. [Detail](geospatial-math-scientific/maplibre-gl-js.md)

### OpenLayers
Feature-rich JS mapping library with strong projection and OGC (WMS/WFS) support; emit `new Map({layers, view})` with tile/vector layers, rendered via Canvas/WebGL. Pick it for heavyweight browser GIS — arbitrary projections and OGC services — beyond what lightweight libraries offer. [Detail](geospatial-math-scientific/openlayers.md)

### Google Maps API
Google's hosted, key-gated JS mapping platform with rich services (geocoding, directions, Places, Street View); emit a script tag plus an `initMap()` using `google.maps.Map`. Pick it when you need Google's data and services out of the box in a commercial app. [Detail](geospatial-math-scientific/google-maps-api.md)

### HERE Maps
Commercial location platform focused on logistics/mobility; emit `H.service.Platform` + `H.Map(...)` browser JS with an API key. Pick it for real-time traffic, transit/isoline routing, and fleet telematics. [Detail](geospatial-math-scientific/here-maps.md)

### deck.gl
WebGL framework for large-scale geospatial layers; emit `new Deck({layers})` with layer classes (Scatterplot, Hexagon, GeoJSON), often overlaid on a base map. Pick it to render millions of points, aggregation layers, or 3D extrusions with GPU performance. [Detail](geospatial-math-scientific/deck_gl.md)

### Kepler.gl
No-code geospatial analytics app built on deck.gl; emit a React/Redux mount (or Python `KeplerGl`) and `addDataToMap(...)` datasets/config, exportable to HTML or PNG. Pick it for point-and-click exploration of large datasets with filtering and time animation, minimal code. [Detail](geospatial-math-scientific/kepler_gl.md)

### Folium
Python library that builds interactive Leaflet maps without JS; emit `folium.Map(...)` plus layers/plugins, saved to a self-contained HTML file or shown in a notebook. Pick it when data lives in Python/pandas and you want an interactive map for EDA, choropleths, or embedding. [Detail](geospatial-math-scientific/folium.md)

### GeoPandas
Python library extending pandas with spatial types and operations; emit `gpd.read_file(...)` plus geometric ops and `.plot(...)`, producing static matplotlib figures or transformed data (needs GDAL/GEOS/PROJ). Pick it for spatial analysis rather than interactive rendering. [Detail](geospatial-math-scientific/geopandas.md)

### Turf.js
Dependency-free JS library for geospatial analysis over GeoJSON; emit `turf.*` calls (distance, buffer, intersect, point-in-polygon) that return GeoJSON for a map to display. Pick it for client-side spatial math without a server round-trip — the JS analog of GeoPandas. [Detail](geospatial-math-scientific/turf_js.md)

#### Math & Scientific

### KaTeX
Fast, dependency-free JS library for rendering TeX math in the browser (with SSR); emit LaTeX math strings plus `katex.render(...)`/`renderToString(...)`, laid out synchronously as HTML/CSS. Pick it when render speed and small size matter. [Detail](geospatial-math-scientific/katex.md)

### MathJax
JS library rendering TeX/LaTeX/MathML with strong accessibility; emit delimited math plus optional config, typeset on load or via `typesetPromise(...)`. Pick it for input-coverage and accessibility (auto MathML, screen readers) over KaTeX's raw speed. [Detail](geospatial-math-scientific/mathjax.md)

### LaTeX
Document preparation system for typeset, math-heavy documents; emit `.tex` source compiled with `pdflatex` (plus bibtex passes) to a PDF. Pick it when the deliverable is a full typeset document — papers, books, reports — with rigorous math and bibliography. [Detail](geospatial-math-scientific/latex.md)

### TikZ/PGF
TeX graphics package for precise vector figures inside a LaTeX document; emit `tikzpicture` source (with `pgfplots`) that renders as part of the PDF compile. Pick it for publication-quality diagrams and plots that share the document's fonts and math typesetting. [Detail](geospatial-math-scientific/tikz-pgf.md)

### Asymptote
Standalone descriptive vector-graphics programming language with native LaTeX; emit `.asy` source compiled by `asy` to PDF/EPS/SVG/PNG or interactive HTML5+WebGL. Pick it for mathematically precise publication figures with stronger native 3D and programmability than TikZ. [Detail](geospatial-math-scientific/asymptote.md)

### MathBox
JS library for animated, interactive 3D math visualization on Three.js/WebGL; emit `MathBox.mathBox(...)` with a cartesian view, surfaces, and clock-driven animation. Pick it for presentation-grade 3D math in the browser — the interactive counterpart to Asymptote's print 3D. [Detail](geospatial-math-scientific/mathbox.md)

### Desmos API
Embeds Desmos's hosted interactive graphing calculator, driven by LaTeX; emit `Desmos.GraphingCalculator(...)` plus `setExpression(...)` with sliders, exportable as a PNG screenshot. Pick it for a polished, student-friendly 2D graphing widget. [Detail](geospatial-math-scientific/desmos-api.md)

### GeoGebra API
Embeds GeoGebra's hosted graphing/geometry/3D/CAS applets; emit `GGBApplet(...)` plus `evalCommand(...)` construction strings. Pick it for a full dynamic-mathematics environment (construction geometry, CAS, 3D), broader than a graphing calculator. [Detail](geospatial-math-scientific/geogebra-api.md)

### JSXGraph
JS library for self-hostable interactive geometry and function plotting; emit `initBoard(...)` plus `board.create(...)` elements (points, sliders, function graphs). Pick it for an embeddable, no-key alternative to the hosted Desmos/GeoGebra applets. [Detail](geospatial-math-scientific/jsxgraph.md)

### SymPy
Pure-Python symbolic mathematics library; emit `symbols(...)` plus algebra/calculus/solve/matrix calls, producing exact symbolic results (optionally LaTeX). Pick it for lightweight, pip-installable symbolic math inside an ordinary Python project. [Detail](geospatial-math-scientific/sympy.md)

### SageMath
Comprehensive open-source math system spanning symbolic math, number theory, algebra, and 2D/3D plotting; emit Sage/Python code run in a notebook (Docker/conda). Pick it when you need a broad, all-in-one environment that subsumes libraries like SymPy. [Detail](geospatial-math-scientific/sagemath.md)

## Source
- Detail files: `fim/overview/geospatial-math-scientific/*.md`
