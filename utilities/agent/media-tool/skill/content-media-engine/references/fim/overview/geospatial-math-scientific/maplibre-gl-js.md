# MapLibre GL JS

## What
MapLibre GL JS is an open-source fork of Mapbox GL JS for WebGL vector-tile maps, requiring no API key. Its primary consumer is browser JavaScript, installed via npm (`maplibre-gl`) and compatible with Mapbox GL style specs.

## How
- The LLM emits **MapLibre GL init JavaScript** — `new maplibregl.Map({container, style: 'https://demotiles.maplibre.org/style.json', center, zoom})`.
- That runs in the browser: raster or vector `source` objects are added and styled with `addLayer(...)` (e.g. `type: 'fill'` over a `source-layer`); controls via `NavigationControl`/`ScaleControl`/`GeolocateControl`; popups via `new maplibregl.Popup()`.
- Self-hosted or third-party vector tiles (protocol-buffer `.pbf`) can back the map; no token required.
- Typical final artifact: a **GPU-rendered interactive vector map**, style-compatible with Mapbox.

## Why
- Reach for MapLibre when you want Mapbox-GL-class vector rendering but need an open-source, no-token, self-hostable stack with an active community — the drop-in choice after Mapbox's licensing change.
- Main tradeoff: you supply your own tile/style infrastructure rather than getting Mapbox's hosted services and Studio tooling out of the box.
- Relative to its siblings: MapLibre is the open fork of `mapbox-gl-js` (same style spec, WebGL vector tiles) and the vector/WebGL counterpart to the lighter raster-tile `leaflet_js`.

## Source
- Solution reference: `fim/solution/maplibre-gl-js.md`
