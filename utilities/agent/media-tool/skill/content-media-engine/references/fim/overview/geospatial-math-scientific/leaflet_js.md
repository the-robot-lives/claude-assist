# Leaflet.js

## What
Leaflet.js is a lightweight (~39–42KB gzipped) mobile-friendly JavaScript library for interactive raster-tile maps. Its primary consumer is browser JavaScript, framework-agnostic (works with React/Vue/Angular or vanilla JS) and usable via CDN or npm.

## How
- The LLM emits **Leaflet init JavaScript** — `L.map('map').setView([lat, lng], zoom)`, then `L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {...}).addTo(map)` and markers via `L.marker([lat, lng]).addTo(map).bindPopup(...)`.
- That runs in the browser after loading `leaflet.css` + `leaflet.js` (CDN or `npm install leaflet`); tile providers, GeoJSON layers, drawing (leaflet-draw), clustering (markercluster), and heatmaps (leaflet.heat) are added as plugins.
- Typical final artifact: an **interactive in-browser map** driven by any tile source (OpenStreetMap, Esri, CARTO, etc.).

## Why
- Reach for Leaflet for interactive web maps with custom markers/overlays and GeoJSON, especially mobile-responsive apps and store-locator / delivery-tracking / real-estate use cases — small footprint, huge plugin ecosystem, no licensing fees, works with any tile provider.
- Limitations: limited 3D compared to Mapbox GL, no built-in data-visualization layers, vector-tile performance weaker than GL libraries, and geocoding/advanced spatial analysis require external services.
- Relative to its siblings: Leaflet is the lightweight **raster-tile** choice; `mapbox-gl-js`/`maplibre-gl-js` render **vector tiles via WebGL** for smoother zoom and 3D, and `folium` wraps Leaflet from Python.

## Source
- Solution reference: `fim/solution/leaflet_js.md`
- Nested use-case detail: `fim/solution/leaflet_js/use-case/geospatial-mapping.md`
