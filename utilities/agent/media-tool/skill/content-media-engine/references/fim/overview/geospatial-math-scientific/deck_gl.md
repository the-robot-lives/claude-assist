# deck.gl

## What
deck.gl is a WebGL-powered JavaScript framework for large-scale data visualization, specializing in GPU-accelerated geospatial layers (scatterplot, hexagon aggregation, GeoJSON, 3D). Its primary consumer is browser JavaScript, installed via npm (`deck.gl`).

## How
- The LLM emits **deck.gl JavaScript** — `import {Deck} from '@deck.gl/core'` and layer classes, then `new Deck({initialViewState, controller: true, layers: [...]})`.
- That runs in the browser: layers such as `ScatterplotLayer`, `HexagonLayer` (with `extruded: true`), and `GeoJsonLayer` are configured with accessors like `getPosition`/`getFillColor`; it integrates with base maps via `MapboxLayer`.
- Typical final artifact: a **GPU-accelerated interactive data-visualization layer**, often overlaid on a Mapbox/MapLibre base map, capable of rendering millions of points.

## Why
- Reach for deck.gl when you must render very large geospatial datasets (millions of points), aggregation layers (hexbin/grid), or 3D extruded visualizations with GPU performance.
- Main tradeoff: it is a visualization layer that typically rides on top of a base-map library rather than a standalone map, and carries the complexity of a layer/accessor framework.
- Relative to its siblings: deck.gl is the high-volume GPU layer engine that composes with `mapbox-gl-js`/`maplibre-gl-js`; `kepler_gl` is a no-code application built on top of deck.gl.

## Source
- Solution reference: `fim/solution/deck_gl.md`
