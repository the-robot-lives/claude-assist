# Mapbox GL JS

## What
Mapbox GL JS is a vector-tile web mapping library with WebGL rendering. Its primary consumer is browser JavaScript, loaded via npm (`mapbox-gl`) and authenticated with a Mapbox access token.

## How
- The LLM emits **Mapbox GL init JavaScript** — set `mapboxgl.accessToken`, then `new mapboxgl.Map({container, style: 'mapbox://styles/mapbox/streets-v12', center, zoom})`.
- That runs in the browser: markers via `new mapboxgl.Marker().setLngLat(...).addTo(map)`; data layers by adding a GeoJSON/raster/vector `source` then an `addLayer({type: 'circle', paint: {...}})`; interactivity via `map.on('click', 'layer', ...)`.
- Requires an access token from account.mapbox.com.
- Typical final artifact: a **GPU-rendered interactive vector map** with smooth zoom, style customization, and 3D terrain/buildings.

## Why
- Reach for Mapbox GL when you need WebGL performance, vector tiles for smooth continuous zoom, deep style customization (Mapbox Studio), and 3D terrain/buildings in a polished commercial app.
- Main tradeoff: it is a token-gated commercial service with usage billing, versus open self-hostable alternatives.
- Relative to its siblings: Mapbox GL is the proprietary origin of the GL rendering approach; `maplibre-gl-js` is its open-source fork (no token, self-hosted tiles), and `leaflet_js` is the lighter raster-tile alternative.

## Source
- Solution reference: `fim/solution/mapbox-gl-js.md`
