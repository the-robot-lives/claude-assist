# deck.gl — GPU-accelerated large-scale geospatial visualization

deck.gl is a WebGL2/WebGPU-powered framework (by vis.gl / OpenJS Foundation, originated at Uber) for rendering **very large** geospatial datasets — millions of points, arcs, hexagon aggregations, 3D extrusions — as composable, data-driven **layers**. It is not a basemap library: it draws overlays that sit on top of (or interleave with) a base map from Mapbox GL, MapLibre, or Google Maps, or it can run standalone with its own `Deck` view. Styling is **accessor-driven**: each visual attribute (`getPosition`, `getFillColor`, `getRadius`) is a function of the datum, uploaded to the GPU.

**Current Version**: deck.gl 9.x (current major)  **License**: MIT  **Runtime**: WebGL2 / WebGPU, no token required (base map may need one)

## Official Resources & Documentation
- **Docs**: https://deck.gl/docs
- **Layer catalog**: https://deck.gl/docs/api-reference/layers
- **Examples/gallery**: https://deck.gl/examples
- **GitHub**: https://github.com/visgl/deck.gl
- **npm**: https://www.npmjs.com/package/deck.gl

## Installation & Setup

### npm
```bash
npm install deck.gl        # umbrella package (all layers)
# or scoped: @deck.gl/core @deck.gl/layers @deck.gl/aggregation-layers @deck.gl/geo-layers @deck.gl/mapbox
```
```javascript
import { Deck } from '@deck.gl/core';
import { ScatterplotLayer } from '@deck.gl/layers';
```

### CDN (scripting / standalone)
```html
<script src="https://unpkg.com/deck.gl@^9/dist.min.js"></script>
<!-- global `deck`: new deck.DeckGL({...}) -->
```

## Core API Reference

### Deck / DeckGL container
```javascript
const deck = new Deck({
  canvas: 'deck-canvas',
  initialViewState: { longitude: -122.4, latitude: 37.8, zoom: 11, pitch: 0, bearing: 0 },
  controller: true,     // enable pan/zoom/rotate
  layers: []
});
deck.setProps({ layers: [ /* new layers */ ] });   // re-render by replacing layer list
```

### The layer model — accessors, not paint
Every layer takes `data` (array/URL/typed arrays) plus **accessor** props. Constant accessors are literals; data-driven accessors are functions `d => value`.
```javascript
new ScatterplotLayer({
  id: 'scatter',
  data: points,
  getPosition: d => d.coordinates,      // [lng, lat] or [lng, lat, alt]
  getRadius: d => d.size,               // meters (default) — radiusUnits controls
  getFillColor: d => [255, 140, 0, 200],// [r,g,b,a] 0–255
  getLineColor: [0, 0, 0],
  radiusScale: 6,
  pickable: true,
  onClick: info => console.log(info.object)
});
```
Colors are **RGBA integer arrays 0–255**, not CSS hex strings.

### Common layers (`@deck.gl/layers`)
- `ScatterplotLayer` — circles (points)
- `IconLayer` — image/sprite markers
- `TextLayer` — labels
- `LineLayer` / `ArcLayer` — segments / great-circle arcs
- `PathLayer` — polylines
- `PolygonLayer` / `SolidPolygonLayer` — filled polygons, 3D extrusion via `getElevation` + `extruded`
- `GeoJsonLayer` — one layer for mixed GeoJSON geometry
- `ColumnLayer` — 3D hexagon/cylinder columns
- `BitmapLayer` — image overlay

### Aggregation layers (`@deck.gl/aggregation-layers`)
- `HexagonLayer` / `GridLayer` — bin points into hex/grid cells, height + color by count
- `HeatmapLayer`, `ContourLayer`, `ScreenGridLayer`

### Geo layers (`@deck.gl/geo-layers`)
- `TileLayer` (raster XYZ), `MVTLayer` (vector tiles), `TerrainLayer`, `Tile3DLayer` (3D Tiles), `TripsLayer` (animated paths), `H3HexagonLayer`, `S2Layer`

### GeoJSON layer
```javascript
new GeoJsonLayer({
  id: 'geojson', data: geojson,
  filled: true, stroked: true, extruded: false,
  getFillColor: [160, 160, 180, 200],
  getLineColor: [255, 255, 255],
  getLineWidth: 2, lineWidthUnits: 'pixels',
  pickable: true
});
```

### Base map integration
Overlay onto Mapbox/MapLibre (interleaved, respects layer order and 3D):
```javascript
import { MapboxOverlay } from '@deck.gl/mapbox';
const overlay = new MapboxOverlay({ interleaved: true, layers: [ scatterLayer ] });
map.addControl(overlay);           // map = mapboxgl.Map or maplibregl.Map
```
Or use `@deck.gl/google-maps` `GoogleMapsOverlay`, or `DeckGL` React component with `react-map-gl`.

### React usage
```jsx
import DeckGL from '@deck.gl/react';
<DeckGL initialViewState={viewState} controller={true} layers={layers} />
```

## Supported Output/Layer Types
Points, icons, text, lines, arcs, paths, polygons (2D/3D extruded), columns, hexbin/grid aggregation, heatmap, contour, screen-grid, GeoJSON, raster/vector/3D tiles, terrain, trips/animation, H3/S2 spatial indexes.

## How-To (worked recipes)

### How to set colors / style a layer (accessors + color scale)
Colors are `[r,g,b]` or `[r,g,b,a]` 0–255. Use a scale library or manual bins to map data → color:
```javascript
import { scaleSequential } from 'd3-scale';
import { interpolateViridis } from 'd3-scale-chromatic';
const color = scaleSequential(interpolateViridis).domain([0, 100]);
function toRGB(css) { const m = css.match(/\d+/g); return [ +m[0], +m[1], +m[2] ]; }

new ScatterplotLayer({ data, getPosition: d => d.pos,
  getFillColor: d => toRGB(color(d.value)),  // data-driven ramp
  getRadius: d => Math.sqrt(d.value) * 100, radiusScale: 1 });
```
For aggregation layers use `colorRange` (array of RGB arrays):
```javascript
new HexagonLayer({ id: 'hex', data, getPosition: d => d.coordinates,
  radius: 1000, extruded: true, elevationScale: 4,
  colorRange: [[255,255,178],[254,204,92],[253,141,60],[240,59,32],[189,0,38]] });
```

### How to overlay millions of points on a base map
```javascript
import { MapboxOverlay } from '@deck.gl/mapbox';
const overlay = new MapboxOverlay({ layers: [
  new ScatterplotLayer({ data: bigArray, getPosition: d => [d.lng, d.lat], getRadius: 30, getFillColor: [255,0,0,120] })
]});
map.addControl(overlay);
```

### How to add hover/click tooltips (picking)
```javascript
new Deck({ /* ... */, getTooltip: ({object}) => object && `${object.name}: ${object.value}` });
// per-layer:
new GeoJsonLayer({ pickable: true, onHover: info => showTooltip(info), onClick: info => select(info.object) });
```

### How to animate trips over time
```javascript
import { TripsLayer } from '@deck.gl/geo-layers';
new TripsLayer({ id: 'trips', data: trips,
  getPath: d => d.path, getTimestamps: d => d.timestamps,
  getColor: [253, 128, 93], trailLength: 180, currentTime: t });  // bump t in a rAF loop
```

### How to draw origin-destination arcs
```javascript
import { ArcLayer } from '@deck.gl/layers';
new ArcLayer({ id: 'arcs', data: flows,
  getSourcePosition: d => d.from,   // [lng, lat]
  getTargetPosition: d => d.to,
  getSourceColor: [0, 128, 200], getTargetColor: [200, 0, 80],
  getWidth: d => Math.sqrt(d.count), widthUnits: 'pixels', pickable: true });
```

## Do's and Don'ts

### ✅ Do
- Use **RGBA integer arrays 0–255** for colors, not hex/CSS strings.
- Set `pickable: true` on layers you want to hover/click.
- Create **new layer instances** each render (deck.gl diffs by `id` and prop identity).
- Use aggregation layers (`HexagonLayer`/`GridLayer`) for density instead of drawing every point.
- Bump `updateTriggers` when an accessor's *captured* variable changes but the function identity doesn't.

### ❌ Don't
- Don't mutate a layer in place — replace the `layers` array / pass a fresh instance.
- Don't forget `updateTriggers: { getFillColor: colorKey }` when a data-driven accessor depends on external state, or the GPU keeps stale colors.
- Don't use deck.gl as a basemap — it draws overlays; pair it with Mapbox/MapLibre/Google or set a solid background.
- Don't pass `[lat, lng]` to `getPosition` — it's `[lng, lat(, alt)]`.
- Don't expect CSS-hex colors to work; convert to arrays.

## Styling, Theming & Customization
- **Data-driven color/size/elevation** via accessor functions.
- **`colorRange`** (RGB array list) for aggregation layers; pair with `colorDomain`.
- **`*Units`** props (`radiusUnits`, `lineWidthUnits`: `'meters'|'pixels'|'common'`) control scaling behavior.
- **Lighting**: `@deck.gl/core` `LightingEffect` + `AmbientLight`/`SunLight` for 3D extrusions; set `material` on layers.
- **Base map theme** comes from the underlying Mapbox/MapLibre style, not deck.gl.

## Advanced Features
- WebGPU renderer (deck.gl 9), `@luma.gl` shader access, custom layers via `Layer` subclassing.
- `@deck.gl/extensions`: `DataFilterExtension`, `BrushingExtension`, `FillStyleExtension`, `PathStyleExtension`.
- 3D Tiles / photogrammetry (`Tile3DLayer`), terrain (`TerrainLayer`), H3/S2 indexes.
- Attribute transitions (`transitions: { getPosition: 600 }`) for animated updates.
- Binary/typed-array data for max throughput; `loaders.gl` for large formats.

## Common Pitfalls & Troubleshooting
- **Colors don't update**: missing `updateTriggers`.
- **Nothing appears**: no base map/background and layers off-screen, or `getPosition` returned undefined.
- **Blurry/wrong colors**: passed hex string instead of RGBA array.
- **Perf collapse**: drawing every point instead of aggregating; or new data array identity each frame without binary attrs.
- **Overlay misaligned with base map**: view state not shared — sync `initialViewState`/`viewState` with the base map, or use `MapboxOverlay` which shares the camera.

## Best For / Avoid For
`big-data-geo`, `millions-of-points`, `3d-hexbin`, `arcs-and-trips`, `gpu-rendering`, `data-driven` — Best for high-volume, animated, 3D geospatial overlays.
Avoid for: simple pin/popup maps (Leaflet), when you need a full styled basemap by itself (Mapbox/MapLibre), heavy vector-editing GIS (OpenLayers).

## See Also
- [mapbox-gl-js.md](mapbox-gl-js.md), [maplibre-gl-js.md](maplibre-gl-js.md) — base maps deck.gl overlays onto
- [kepler_gl.md](kepler_gl.md) — no-code app built on deck.gl
- [leaflet_js.md](leaflet_js.md) — lightweight alternative for small data
- [turf_js.md](turf_js.md) — preprocess GeoJSON before feeding layers
- `../use-case/geospatial-mapping.md`, `../solution/three_js.md`
