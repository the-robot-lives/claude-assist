# Folium

## What
Folium is a Python library that builds interactive Leaflet.js maps from Python code, letting you visualize geospatial data (markers, choropleths, heatmaps, layers) without writing JavaScript. Its primary consumer is a Python runtime — typically a Jupyter notebook or a web framework (Flask/Django) that serves the generated map.

## How
- The LLM emits **Python/Folium code** — `folium.Map(...)` plus marker/layer/plugin calls (e.g. `folium.plugins.HeatMap`, `MarkerCluster`, `TimestampedGeoJson`).
- That code is run in a Python environment; a base map is created with `folium.Map(location=[lat, lon], zoom_start=..., tiles='OpenStreetMap')`, layers are added with `.add_to(m)`, and the map is saved to disk (`m.save('map.html')`) or displayed inline in a notebook.
- Typical final artifact: a **self-contained interactive HTML/CSS/JS map** that renders in any modern browser.

## Why
- Reach for Folium when the data lives in Python/pandas and you want an interactive Leaflet map without touching JS — ideal for exploratory analysis, choropleth/statistical mapping, and embedding maps in Python web apps or research notebooks.
- Limitations: output is **static once generated** (no live updates without regeneration), performance degrades on very large datasets (>100k points), it is 2D-focused with limited 3D and animation support, and it cannot run outside a Python environment.
- Relative to its siblings: Folium is the Python front-end to the same Leaflet.js engine that `leaflet_js` uses directly — choose Folium for a Python-driven pipeline, raw Leaflet for a JS/browser app; use `geopandas` when you need spatial *analysis* rather than an interactive map.

## Source
- Solution reference: `fim/solution/folium.md`
