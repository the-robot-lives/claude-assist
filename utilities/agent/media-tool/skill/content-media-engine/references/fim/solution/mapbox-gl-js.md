# Mapbox GL JS — WebGL vector-tile mapping with a declarative style spec

Mapbox GL JS renders interactive maps from **vector tiles** using WebGL, giving smooth continuous zoom, client-side styling, tilt/rotation (pitch/bearing), 3D terrain and extruded buildings. Maps are described by a JSON **style spec** (`version 8`) made of `sources` and `layers`; layer appearance is set with data-driven **`paint`** and **`layout`** properties and **expressions**. Requires an access token and (since v2) is under Mapbox's proprietary TOS — for a token-free drop-in use MapLibre GL JS (near-identical API).

**Current Version**: mapbox-gl 3.x (current major)  **License**: Proprietary (Mapbox TOS; billed by map loads)  **Runtime**: WebGL 2, token required

## Official Resources & Documentation
- **Docs**: https://docs.mapbox.com/mapbox-gl-js/guides/
- **Style Specification**: https://docs.mapbox.com/style-spec/reference/
- **API reference**: https://docs.mapbox.com/mapbox-gl-js/api/
- **Examples**: https://docs.mapbox.com/mapbox-gl-js/example/
- **npm**: https://www.npmjs.com/package/mapbox-gl
- **Get a token**: https://account.mapbox.com/access-tokens/

## Installation & Setup

### npm
```bash
npm install mapbox-gl
```
```javascript
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';   // REQUIRED for controls/popups
mapboxgl.accessToken = 'pk.your_token_here';
```

### CDN
```html
<link href="https://api.mapbox.com/mapbox-gl-js/v3.9.0/mapbox-gl.css" rel="stylesheet">
<script src="https://api.mapbox.com/mapbox-gl-js/v3.9.0/mapbox-gl.js"></script>
```

## Core API Reference

### Map — `new mapboxgl.Map(options)`
```javascript
const map = new mapboxgl.Map({
  container: 'map',
  style: 'mapbox://styles/mapbox/streets-v12',  // or a full style JSON object / URL
  center: [-74.5, 40],   // [lng, lat] — lng FIRST (GeoJSON order)
  zoom: 9,
  pitch: 0,              // 0–85 tilt
  bearing: 0,            // rotation degrees
  antialias: true
});
```
Built-in styles: `streets-v12`, `outdoors-v12`, `light-v11`, `dark-v11`, `satellite-v9`, `satellite-streets-v12`, `navigation-day-v1`.

Lifecycle: register work in the `load` event — `sources`/`layers` can only be added after the style loads.
```javascript
map.on('load', () => { /* addSource / addLayer here */ });
```

### Sources — `map.addSource(id, spec)`
```javascript
// GeoJSON
map.addSource('pts', { type: 'geojson', data: featureCollection });
// Vector tiles
map.addSource('v', { type: 'vector', url: 'mapbox://mapbox.mapbox-streets-v8' });
// Raster XYZ
map.addSource('r', { type: 'raster', tiles: ['https://tile.example.com/{z}/{x}/{y}.png'], tileSize: 256 });
// Raster-DEM (for terrain/hillshade)
map.addSource('dem', { type: 'raster-dem', url: 'mapbox://mapbox.mapbox-terrain-dem-v1' });
// Image overlay
map.addSource('img', { type: 'image', url: 'photo.png', coordinates: [[tl],[tr],[br],[bl]] });
```
Update GeoJSON live: `map.getSource('pts').setData(newFeatureCollection)`.

### Layers — `map.addLayer(spec, beforeId?)`
Layer `type` determines which `paint`/`layout` keys apply: `circle`, `line`, `fill`, `fill-extrusion`, `symbol` (icons + text), `heatmap`, `raster`, `hillshade`, `background`, `sky`.
```javascript
map.addLayer({
  id: 'pts-layer',
  type: 'circle',
  source: 'pts',
  paint: { 'circle-radius': 6, 'circle-color': '#007cbf', 'circle-stroke-width': 1, 'circle-stroke-color': '#fff' }
});
```
Vector/tiled sources also need `'source-layer'`. `beforeId` inserts beneath an existing layer for correct stacking.

### paint vs layout
- **`layout`** = how features are laid out (evaluated earlier): `visibility`, `line-cap`, `text-field`, `icon-image`, `symbol-placement`.
- **`paint`** = color/opacity/size at draw time: `*-color`, `*-opacity`, `*-width`, `*-radius`, `fill-extrusion-height`.
```javascript
map.setPaintProperty('pts-layer', 'circle-color', '#f30');
map.setLayoutProperty('pts-layer', 'visibility', 'none');
```

### Expressions (data-driven styling)
Expressions are JSON arrays `[operator, ...args]`. Common: `get`, `interpolate`, `step`, `match`, `case`, `zoom`, `heatmap-density`.
```javascript
'circle-color': ['interpolate', ['linear'], ['get', 'value'],
  0, '#ffffcc', 50, '#fd8d3c', 100, '#e31a1c']
'circle-radius': ['interpolate', ['linear'], ['zoom'], 5, 2, 15, 12]
'fill-color': ['match', ['get', 'type'], 'park', '#3a3', 'water', '#39f', /* default */ '#ccc']
```

### Markers, popups, controls
```javascript
new mapboxgl.Marker({color: '#e11'}).setLngLat([-74.5, 40]).setPopup(new mapboxgl.Popup().setHTML('<b>Hi</b>')).addTo(map);
new mapboxgl.Popup().setLngLat([-74.5, 40]).setHTML('Info').addTo(map);
map.addControl(new mapboxgl.NavigationControl());
map.addControl(new mapboxgl.ScaleControl());
map.addControl(new mapboxgl.GeolocateControl({trackUserLocation: true}));
map.addControl(new mapboxgl.FullscreenControl());
```
`Marker` = DOM/HTML element (always on top); a `symbol` layer = GPU-rendered, scales to millions.

### Events
```javascript
map.on('click', 'pts-layer', e => {
  const f = e.features[0];
  new mapboxgl.Popup().setLngLat(f.geometry.coordinates).setHTML(f.properties.name).addTo(map);
});
map.on('mouseenter', 'pts-layer', () => map.getCanvas().style.cursor = 'pointer');
map.on('mouseleave', 'pts-layer', () => map.getCanvas().style.cursor = '');
```

## Supported Layer Types
`circle`, `line`, `fill`, `fill-extrusion` (3D), `symbol` (icons/labels), `heatmap`, `raster`, `hillshade`, `background`, `sky`. Sources: `geojson`, `vector`, `raster`, `raster-dem`, `image`, `video`.

## How-To (worked recipes)

### How to set colors / style a layer (paint + expressions)
Static color:
```javascript
map.addLayer({ id: 'zones', type: 'fill', source: 'zones',
  paint: { 'fill-color': '#088', 'fill-opacity': 0.5, 'fill-outline-color': '#044' } });
```
Data-driven ramp with an interpolate expression:
```javascript
map.setPaintProperty('zones', 'fill-color',
  ['interpolate', ['linear'], ['get', 'density'],
    0, '#f2f0f7', 500, '#9e9ac8', 1000, '#54278f']);
```
Categorical with `match`:
```javascript
map.setPaintProperty('zones', 'fill-color',
  ['match', ['get', 'zone'], 'A', '#e41a1c', 'B', '#377eb8', /* default */ '#999']);
```

### How to add a GeoJSON layer with a legend/heatmap
```javascript
map.addSource('quakes', { type: 'geojson', data: '/quakes.geojson' });
map.addLayer({ id: 'heat', type: 'heatmap', source: 'quakes',
  paint: {
    'heatmap-weight': ['interpolate', ['linear'], ['get', 'mag'], 0, 0, 6, 1],
    'heatmap-color': ['interpolate', ['linear'], ['heatmap-density'],
      0, 'rgba(0,0,255,0)', 0.5, 'lime', 1, 'red'],
    'heatmap-radius': 20
  }});
```

### How to add labels (symbol layer)
```javascript
map.addLayer({ id: 'labels', type: 'symbol', source: 'pts',
  layout: { 'text-field': ['get', 'name'], 'text-size': 12, 'text-offset': [0, 1.2], 'text-anchor': 'top' },
  paint: { 'text-color': '#333', 'text-halo-color': '#fff', 'text-halo-width': 1 } });
```

### How to add 3D terrain and extruded buildings
```javascript
map.addSource('dem', { type: 'raster-dem', url: 'mapbox://mapbox.mapbox-terrain-dem-v1' });
map.setTerrain({ source: 'dem', exaggeration: 1.5 });
map.addLayer({ id: '3d-buildings', source: 'composite', 'source-layer': 'building',
  type: 'fill-extrusion', minzoom: 14,
  paint: { 'fill-extrusion-height': ['get', 'height'], 'fill-extrusion-color': '#aaa', 'fill-extrusion-opacity': 0.7 } });
```

## Do's and Don'ts

### ✅ Do
- Add sources/layers inside `map.on('load', ...)`.
- Use `[lng, lat]` order everywhere (GeoJSON convention).
- Import `mapbox-gl.css` — controls and popups depend on it.
- Prefer `symbol`/`circle` layers over thousands of DOM `Marker`s.
- Use `setData()` to update GeoJSON instead of removing/re-adding the source.
- Insert layers with a `beforeId` to control stacking (labels above fills).

### ❌ Don't
- Don't call `addLayer` before the style loads → "Style is not done loading".
- Don't put `*-color` in `layout` or `text-field` in `paint` — they're split; wrong bucket silently no-ops.
- Don't ship an unrestricted token in client code without URL restrictions (billing abuse).
- Don't use hundreds of `Marker` DOM nodes for large datasets — they kill performance.
- Don't assume Mapbox and MapLibre tokens/styles are interchangeable — MapLibre can't load `mapbox://` styles.

## Styling, Theming & Customization
- **Whole-map theme**: swap `style` (`dark-v11`, `light-v11`, `satellite-streets-v12`) or author a custom style in Mapbox Studio.
- **Runtime restyle**: `setPaintProperty` / `setLayoutProperty` / `setLayerZoomRange`.
- **Color ramps**: `interpolate` (continuous) or `step` (binned) expressions on any `*-color`.
- **Fog/sky/light**: `map.setFog({...})`, a `sky` layer, `map.setLight({...})` for extrusion shading.
- **Filter**: `map.setFilter('layer', ['==', ['get', 'category'], 'x'])`.

## Advanced Features
- 3D terrain (`setTerrain`), `fill-extrusion` buildings, globe projection (`projection: 'globe'`).
- Camera animation: `flyTo`, `easeTo`, `fitBounds`, `jumpTo`.
- `queryRenderedFeatures` / `querySourceFeatures` for hit-testing and data reads.
- Custom WebGL layers (`type: 'custom'`) and deck.gl interleaving via `MapboxOverlay`.
- Draw tools via `@mapbox/mapbox-gl-draw`; geocoding via `@mapbox/mapbox-gl-geocoder`.

## Common Pitfalls & Troubleshooting
- **Blank map**: missing token, missing CSS, or WebGL disabled/unsupported.
- **"Style is not done loading"**: adding layers outside the `load` event.
- **Nothing renders from a vector source**: missing/incorrect `'source-layer'`.
- **Coordinates off**: lat/lng swapped (Mapbox is `[lng, lat]`).
- **Billing surprise**: every map init counts as a map load; restrict the token and cache.

## Best For / Avoid For
`vector-maps`, `3d-terrain`, `data-driven-styling`, `smooth-zoom`, `navigation`, `large-point-sets` — Best for polished commercial vector maps with rich styling and 3D.
Avoid for: token-free/self-hosted needs (use MapLibre), tiny "just a pin" widgets (Leaflet is lighter), millions of animated points with custom WebGL (deck.gl).

## See Also
- [maplibre-gl-js.md](maplibre-gl-js.md) — open-source, token-free fork with the same style spec
- [leaflet_js.md](leaflet_js.md) — lighter raster/DOM alternative
- [deck_gl.md](deck_gl.md) — GPU overlays interleaved with Mapbox
- [openlayers.md](openlayers.md) — projection-heavy alternative
- [turf_js.md](turf_js.md) — geospatial analysis for GeoJSON feeding sources
- `../use-case/geospatial-mapping.md`
