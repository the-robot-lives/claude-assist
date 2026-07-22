# MapLibre GL JS — Open-source WebGL vector maps (Mapbox GL fork)

MapLibre GL JS is the community-governed, BSD-licensed fork of Mapbox GL JS v1, created when Mapbox moved to a proprietary license. It renders vector and raster tiles with WebGL using the same **`version: 8` style spec** — `sources`, `layers`, `paint`/`layout` properties, and expressions — so almost all Mapbox GL knowledge transfers directly. Crucially, **no access token is required**; you point it at any style JSON (self-hosted, MapTiler, Stadia, OpenFreeMap, demotiles). This makes it the default choice for open-data maps and self-hosted vector tile stacks.

**Current Version**: maplibre-gl 4.x / 5.x (current major)  **License**: BSD-3-Clause  **Runtime**: WebGL 2, no token required

## Official Resources & Documentation
- **Docs**: https://maplibre.org/maplibre-gl-js/docs/
- **Style Spec**: https://maplibre.org/maplibre-style-spec/
- **API reference**: https://maplibre.org/maplibre-gl-js/docs/API/
- **Examples**: https://maplibre.org/maplibre-gl-js/docs/examples/
- **GitHub**: https://github.com/maplibre/maplibre-gl-js
- **npm**: https://www.npmjs.com/package/maplibre-gl
- **Free styles/tiles**: https://openfreemap.org/, https://www.maptiler.com/, demotiles at https://demotiles.maplibre.org/style.json

## Installation & Setup

### npm
```bash
npm install maplibre-gl
```
```javascript
import maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';   // REQUIRED
```

### CDN
```html
<link href="https://unpkg.com/maplibre-gl@4/dist/maplibre-gl.css" rel="stylesheet">
<script src="https://unpkg.com/maplibre-gl@4/dist/maplibre-gl.js"></script>
```

## Core API Reference

The class surface mirrors Mapbox GL (`Map`, `Marker`, `Popup`, `NavigationControl`, ...) under the `maplibregl` namespace — no `accessToken` assignment.

### Map
```javascript
const map = new maplibregl.Map({
  container: 'map',
  style: 'https://demotiles.maplibre.org/style.json',  // any style URL or inline JSON
  center: [0, 0],   // [lng, lat]
  zoom: 2,
  pitch: 0,
  bearing: 0
});
map.on('load', () => { /* add sources & layers */ });
```

### Inline style object (fully self-hosted, no external style needed)
```javascript
const style = {
  version: 8,
  sources: {
    osm: { type: 'raster', tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'], tileSize: 256, attribution: '© OpenStreetMap' }
  },
  layers: [{ id: 'osm', type: 'raster', source: 'osm' }]
};
const map = new maplibregl.Map({ container: 'map', style, center: [0, 0], zoom: 2 });
```

### Sources
```javascript
map.addSource('pts', { type: 'geojson', data: featureCollection });
map.addSource('v', { type: 'vector', tiles: ['https://example.com/tiles/{z}/{x}/{y}.pbf'], maxzoom: 14 });
map.addSource('r', { type: 'raster', tiles: ['https://tile.example.com/{z}/{x}/{y}.png'], tileSize: 256 });
map.addSource('dem', { type: 'raster-dem', url: 'https://.../terrain.json' });  // terrain/hillshade
```
Live update: `map.getSource('pts').setData(newData)`.

### Layers (same paint/layout as Mapbox)
```javascript
map.addLayer({
  id: 'buildings', type: 'fill', source: 'v', 'source-layer': 'buildings',
  paint: { 'fill-color': '#088', 'fill-opacity': 0.8, 'fill-outline-color': '#044' }
});
map.addLayer({
  id: 'pts-layer', type: 'circle', source: 'pts',
  paint: { 'circle-radius': 6, 'circle-color': '#e11', 'circle-stroke-color': '#fff', 'circle-stroke-width': 1 }
});
```
Layer types: `circle`, `line`, `fill`, `fill-extrusion`, `symbol`, `heatmap`, `raster`, `hillshade`, `background`. Runtime: `map.setPaintProperty(id, prop, value)`, `map.setLayoutProperty(id, 'visibility', 'none')`.

### Expressions (identical grammar to Mapbox)
```javascript
'fill-color': ['interpolate', ['linear'], ['get', 'pop'], 0, '#edf8fb', 5000, '#005824']
'circle-radius': ['interpolate', ['linear'], ['zoom'], 4, 2, 14, 10]
'line-color': ['match', ['get', 'class'], 'motorway', '#e00', 'primary', '#f80', '#999']
```

### Controls, markers, popups
```javascript
map.addControl(new maplibregl.NavigationControl());
map.addControl(new maplibregl.ScaleControl());
map.addControl(new maplibregl.GeolocateControl({ trackUserLocation: true }));
new maplibregl.Marker({ color: '#e11' }).setLngLat([lng, lat]).addTo(map);
new maplibregl.Popup().setLngLat([lng, lat]).setHTML('<h3>Location</h3>').addTo(map);
```

### Events
```javascript
map.on('click', 'pts-layer', e => {
  const c = e.features[0].geometry.coordinates.slice();
  new maplibregl.Popup().setLngLat(c).setHTML(e.features[0].properties.name).addTo(map);
});
```

## Supported Layer & Source Types
Layers: `circle`, `line`, `fill`, `fill-extrusion`, `symbol`, `heatmap`, `raster`, `hillshade`, `background`. Sources: `geojson`, `vector`, `raster`, `raster-dem`, `image`, `video`. Terrain via `map.setTerrain({ source, exaggeration })`.

## How-To (worked recipes)

### How to set colors / style a layer
Same `paint` + expression model as Mapbox. Static:
```javascript
map.addLayer({ id: 'land', type: 'fill', source: 'v', 'source-layer': 'landuse',
  paint: { 'fill-color': '#c8e6c9', 'fill-opacity': 0.6 } });
```
Data-driven ramp and categorical:
```javascript
map.setPaintProperty('land', 'fill-color',
  ['interpolate', ['linear'], ['get', 'value'], 0, '#fff7ec', 100, '#7f0000']);
map.setPaintProperty('roads', 'line-color',
  ['match', ['get', 'kind'], 'rail', '#555', 'path', '#8a6', /* default */ '#999']);
```

### How to build a self-hosted map with no API key
Use the inline `style` object above pointed at OpenStreetMap raster or your own `.pbf` vector tiles + OpenFreeMap. No token, no billing.
```javascript
const map = new maplibregl.Map({ container: 'map',
  style: 'https://tiles.openfreemap.org/styles/liberty', center: [2.35, 48.85], zoom: 12 });
```

### How to add a layer switcher / toggle visibility
```javascript
document.getElementById('toggle').onclick = () => {
  const vis = map.getLayoutProperty('buildings', 'visibility');
  map.setLayoutProperty('buildings', 'visibility', vis === 'none' ? 'visible' : 'none');
};
```

### How to add 3D terrain + hillshade (token-free with MapTiler/self-host)
```javascript
map.addSource('terrain', { type: 'raster-dem', url: 'https://api.maptiler.com/tiles/terrain-rgb/tiles.json?key=KEY' });
map.setTerrain({ source: 'terrain', exaggeration: 1.4 });
map.addLayer({ id: 'hills', type: 'hillshade', source: 'terrain' });
```

### How to cluster a GeoJSON point source
Clustering is built into the `geojson` source; style the cluster and count with two layers.
```javascript
map.addSource('pts', { type: 'geojson', data: '/points.geojson', cluster: true, clusterRadius: 50, clusterMaxZoom: 14 });
map.addLayer({ id: 'clusters', type: 'circle', source: 'pts', filter: ['has', 'point_count'],
  paint: { 'circle-color': ['step', ['get', 'point_count'], '#51bbd6', 100, '#f1f075', 750, '#f28cb1'],
           'circle-radius': ['step', ['get', 'point_count'], 15, 100, 25, 750, 35] } });
map.addLayer({ id: 'cluster-count', type: 'symbol', source: 'pts', filter: ['has', 'point_count'],
  layout: { 'text-field': ['get', 'point_count_abbreviated'], 'text-size': 12 } });
map.addLayer({ id: 'unclustered', type: 'circle', source: 'pts', filter: ['!', ['has', 'point_count']],
  paint: { 'circle-color': '#11b4da', 'circle-radius': 6, 'circle-stroke-width': 1, 'circle-stroke-color': '#fff' } });
```

### How to load single-file tiles with PMTiles (fully static hosting)
```javascript
import { Protocol } from 'pmtiles';
const protocol = new Protocol();
maplibregl.addProtocol('pmtiles', protocol.tile);
map.addSource('v', { type: 'vector', url: 'pmtiles://https://example.com/tiles.pmtiles' });
```

## Do's and Don'ts

### ✅ Do
- Use MapLibre when you need a **token-free / self-hosted** map — the reason it exists.
- Reuse Mapbox GL examples: the style spec, `paint`/`layout`, and expressions are the same.
- Add sources/layers in the `load` handler.
- Provide `attribution` in raster/vector source specs — OSM requires it.
- Point `style` at a real MapLibre-style JSON (demotiles, OpenFreeMap, MapTiler).

### ❌ Don't
- Don't load `mapbox://styles/...` URLs — MapLibre cannot resolve the `mapbox://` scheme or Mapbox-hosted tiles.
- Don't set `mapboxgl.accessToken` — there is no such requirement (a leftover Mapbox token line is a common copy-paste bug).
- Don't mix `mapbox-gl` and `maplibre-gl` plugin builds — use MapLibre-compatible plugins.
- Don't forget the CSS import; controls/popups break without it.
- Don't swap `[lng, lat]` order.

## Styling, Theming & Customization
- **Theme = the style JSON.** Swap `style` URLs for light/dark/satellite (MapTiler `basic`/`streets`/`darkmatter`, OpenFreeMap `liberty`/`bright`/`positron`).
- **Runtime restyle** via `setPaintProperty` / `setLayoutProperty` / `setFilter`.
- **Color ramps** with `interpolate`/`step` expressions on any `*-color`.
- **Sprite & glyphs**: the style's `sprite` and `glyphs` URLs supply icons and label fonts; self-host both for offline maps.

## Advanced Features
- Terrain, hillshade, `fill-extrusion` 3D, globe projection (recent versions).
- `queryRenderedFeatures` for hit-testing.
- deck.gl interop via `@deck.gl/mapbox` `MapboxOverlay` (works with MapLibre).
- Plugins: `@maplibre/maplibre-gl-geocoder`, `maplibre-gl-draw`, PMTiles protocol for single-file tile archives.

## Common Pitfalls & Troubleshooting
- **Blank map / 404 on tiles**: style URL requires a key you didn't supply, or CORS blocked.
- **`mapbox://` won't load**: use a MapLibre-native style URL instead.
- **"Style is not done loading"**: added layers before `load`.
- **Missing labels/icons**: style's `glyphs`/`sprite` endpoints unreachable.
- **Vector source shows nothing**: wrong or missing `'source-layer'`.

## Best For / Avoid For
`open-source-maps`, `self-hosted-tiles`, `token-free`, `vector-maps`, `data-driven-styling` — Best when you want Mapbox-GL capabilities without the proprietary license or token/billing.
Avoid for: Mapbox-hosted styles/tiles specifically (use Mapbox GL), ultra-light "one pin" widgets (Leaflet), massive custom-WebGL point animation (deck.gl).

## See Also
- [mapbox-gl-js.md](mapbox-gl-js.md) — upstream API this mirrors; the style-spec reference applies
- [leaflet_js.md](leaflet_js.md) — lighter raster/DOM alternative
- [openlayers.md](openlayers.md) — projection-rich alternative
- [deck_gl.md](deck_gl.md) — GPU overlay layer, MapLibre-compatible
- [turf_js.md](turf_js.md) — client-side GeoJSON analysis
- `../use-case/geospatial-mapping.md`
