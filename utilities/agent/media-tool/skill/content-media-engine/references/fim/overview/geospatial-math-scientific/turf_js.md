# Turf.js

## What
Turf.js is a dependency-free JavaScript library for geospatial analysis, offering 85+ spatial operations over GeoJSON. It runs in both the browser and Node.js and produces data (GeoJSON), not visuals — it is a computation layer, not a renderer.

## How
- The LLM emits **Turf.js JavaScript** — `import * as turf from '@turf/turf'` (or specific modules), then calls like `turf.distance(from, to, {units})`, `turf.buffer(...)`, `turf.intersect/union/difference(...)`, `turf.booleanPointInPolygon(...)`, `turf.centroid(...)`, `turf.simplify(...)`.
- That runs in the browser or Node: it consumes and returns GeoJSON geometries, which are then handed to a mapping library for display.
- Typical final artifact: **GeoJSON results** (distances, buffers, intersections, tagged points) fed into a map or further logic.

## Why
- Reach for Turf.js when you need client-side spatial math — measuring distance, buffering, boolean polygon ops, point-in-polygon tests, spatial joins, interpolation — without a server round-trip or heavy dependencies.
- Main tradeoff: it computes but does not render, and (per its modular GeoJSON design) it is not a full GIS stack — pair it with a map library for visualization.
- Relative to its siblings: Turf.js is the analysis complement to renderers like `leaflet_js`/`mapbox-gl-js`, and the JavaScript-side analog of Python's `geopandas` for geometric operations.

## Source
- Solution reference: `fim/solution/turf_js.md`
