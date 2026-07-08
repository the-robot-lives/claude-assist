# OpenLayers

## What
OpenLayers is a high-performance, feature-rich JavaScript library for interactive maps with strong support for many tile sources, projections, and OGC web services. Its primary consumer is browser JavaScript, installed via npm (`ol`) using ES module imports.

## How
- The LLM emits **OpenLayers JavaScript** — importing `Map`, `View`, `TileLayer`, and sources like `OSM`, then `new Map({target, layers: [...], view: new View({center, zoom})})`.
- That runs in the browser: vector data via `VectorLayer` + `VectorSource` with a `GeoJSON` format; drawing via the `Draw` interaction; OGC services via `TileWMS`; styling with `Style`/`Fill`/`Stroke`/`Circle`.
- Renders through Canvas and WebGL.
- Typical final artifact: an **interactive in-browser map** with advanced projection and WMS/WFS handling.

## Why
- Reach for OpenLayers when you need heavyweight GIS capability in the browser — arbitrary projections, WMS/WFS/OGC services, and rich interaction tools — beyond what lightweight libraries offer.
- Main tradeoff: a larger, more complex API surface than Leaflet, so more setup for simple maps.
- Relative to its siblings: OpenLayers is the full-featured GIS-oriented alternative to the minimalist `leaflet_js`, and unlike `mapbox-gl-js`/`maplibre-gl-js` it is provider-agnostic with first-class OGC/projection support rather than a vector-tile-first design.

## Source
- Solution reference: `fim/solution/openlayers.md`
