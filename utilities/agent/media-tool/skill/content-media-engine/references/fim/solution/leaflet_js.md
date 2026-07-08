# Leaflet.js — Lightweight interactive maps for web and mobile

Leaflet is the most widely used open-source JavaScript library for interactive maps. It renders raster and vector tile basemaps, overlays (markers, popups, vector shapes, GeoJSON), and UI controls into an HTML container using DOM/SVG/Canvas — no WebGL, no API key, ~42KB gzipped. It runs in every modern browser and has first-class touch support, making it the default choice for store locators, real-estate maps, delivery tracking, and any 2D "pins on a map" task.

**Current Version**: 1.9.4 (current stable; 2.0 in beta)  **License**: BSD-2-Clause  **Bundle**: ~42KB gzipped JS + required CSS

## Official Resources & Documentation
- **Docs / API reference**: https://leafletjs.com/reference.html
- **Tutorials**: https://leafletjs.com/examples.html
- **GitHub**: https://github.com/Leaflet/Leaflet
- **npm**: https://www.npmjs.com/package/leaflet
- **Plugin directory**: https://leafletjs.com/plugins.html
- **Tile providers preview**: https://leaflet-extras.github.io/leaflet-providers/preview/

## Installation & Setup

### npm / bundler
```bash
npm install leaflet
```
```javascript
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';   // REQUIRED — map is broken without it
```

### CDN (browser)
```html
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
  integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
  integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
```
The container needs an explicit height or the map renders 0px tall:
```html
<div id="map" style="height: 400px;"></div>
```

## Core API Reference

Leaflet's API is a hierarchy of classes created with lowercase factory functions (`L.map`, `L.marker`) — calling `L.Marker` with `new` also works. Almost every method returns the object for chaining.

### Map — `L.map(id, options)`
```javascript
const map = L.map('map', {
  center: [51.505, -0.09],   // [lat, lng] — NOTE lat first (opposite of GeoJSON)
  zoom: 13,
  minZoom: 3, maxZoom: 19,
  zoomControl: true,
  scrollWheelZoom: true,
  attributionControl: true
});
// or fluent:
const map2 = L.map('map').setView([51.505, -0.09], 13);
```
Key methods: `setView(latlng, zoom)`, `flyTo(latlng, zoom)`, `fitBounds(bounds)`, `panTo(latlng)`, `getZoom()`, `getBounds()`, `getCenter()`, `invalidateSize()` (call after the container resizes or unhides).

### Tile layers — `L.tileLayer(urlTemplate, options)`
```javascript
L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
  maxZoom: 19,
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
}).addTo(map);
```
`{s}` = subdomain, `{z}/{x}/{y}` = zoom/column/row, `{r}` = "@2x" retina suffix. WMS: `L.tileLayer.wms(url, {layers, format, transparent})`.

### Markers, icons, popups, tooltips
```javascript
const m = L.marker([51.5, -0.09]).addTo(map);
m.bindPopup('<b>Hello</b>').openPopup();
m.bindTooltip('Hover text');

const icon = L.icon({
  iconUrl: 'pin.png', iconSize: [25, 41], iconAnchor: [12, 41], popupAnchor: [1, -34]
});
L.marker([51.5, -0.1], {icon, draggable: true}).addTo(map);

// DOM-based icon (styleable with CSS, no image asset)
const div = L.divIcon({className: 'my-pin', html: '📍', iconSize: [30, 30]});
L.marker([51.51, -0.1], {icon: div}).addTo(map);
```

### Vector overlays
```javascript
L.circle([51.508, -0.11], {radius: 500, color: '#e11', fillColor: '#f66', fillOpacity: 0.4}).addTo(map);
L.circleMarker([51.5, -0.09], {radius: 8}).addTo(map);   // radius in px, not meters
L.polyline([[51.5,-0.1],[51.51,-0.12]], {color: '#06f', weight: 4}).addTo(map);
L.polygon([[51.5,-0.1],[51.51,-0.09],[51.49,-0.08]], {color: '#093'}).addTo(map);
L.rectangle([[51.49,-0.12],[51.5,-0.10]]).addTo(map);
```

### GeoJSON — `L.geoJSON(data, options)`
```javascript
L.geoJSON(featureCollection, {
  style: feature => ({color: feature.properties.color || '#333', weight: 2}),
  pointToLayer: (feat, latlng) => L.circleMarker(latlng, {radius: 6}),
  onEachFeature: (feat, layer) => layer.bindPopup(feat.properties.name),
  filter: feat => feat.properties.visible !== false
}).addTo(map);
```
GeoJSON coordinates are `[lng, lat]`; Leaflet's own `LatLng` is `[lat, lng]` — `L.geoJSON` handles the swap for you, but hand-built `L.marker` calls do not.

### Controls
```javascript
L.control.zoom({position: 'topleft'}).addTo(map);
L.control.scale({imperial: false}).addTo(map);
L.control.layers(baseLayers, overlays).addTo(map);   // layer switcher
```
Custom control: extend `L.Control`, implement `onAdd(map)` returning a DOM element.

### Layer groups
```javascript
const group = L.layerGroup([markerA, markerB]).addTo(map);
const fg = L.featureGroup([...]).addTo(map);
map.fitBounds(fg.getBounds());   // featureGroup exposes combined bounds
```

## Supported Layer & Source Types
- **Raster tiles**: `L.tileLayer` (XYZ/TMS), `L.tileLayer.wms` (OGC WMS)
- **Image/video overlay**: `L.imageOverlay(url, bounds)`, `L.videoOverlay`
- **Vector**: `L.marker`, `L.circle`, `L.circleMarker`, `L.polyline`, `L.polygon`, `L.rectangle`, `L.geoJSON`
- **Grouping**: `L.layerGroup`, `L.featureGroup`, `L.geoJSON`
- **Plugins**: heatmaps (Leaflet.heat), clustering (Leaflet.markercluster), routing (Leaflet Routing Machine), vector tiles (Leaflet.VectorGrid), draw (Leaflet.draw)

## How-To (worked recipes)

### How to set colors / style a layer
Vector layers take a **Path options** object; override any of `color` (stroke), `weight`, `opacity`, `fillColor`, `fillOpacity`, `dashArray`, `lineCap`.
```javascript
L.polygon(coords, {
  color: '#2c7fb8',      // stroke
  weight: 2,
  fillColor: '#7fcdbb',  // fill (defaults to `color` if omitted)
  fillOpacity: 0.6,
  dashArray: '5,5'
}).addTo(map);

// Data-driven color ramp for GeoJSON
function ramp(v) { return v > 100 ? '#800026' : v > 50 ? '#E31A1C' : v > 10 ? '#FD8D3C' : '#FFEDA0'; }
L.geoJSON(data, { style: f => ({fillColor: ramp(f.properties.value), fillOpacity: 0.7, weight: 1, color: '#fff'}) }).addTo(map);
```
For marker icons, style a `L.divIcon` with a CSS class instead of shipping PNGs.

### How to add a legend and a data-driven choropleth
```javascript
const legend = L.control({position: 'bottomright'});
legend.onAdd = function () {
  const div = L.DomUtil.create('div', 'legend');
  const grades = [0, 10, 50, 100];
  grades.forEach((g, i) => {
    div.innerHTML += `<i style="background:${ramp(g + 1)}"></i> ${g}${grades[i+1] ? '&ndash;'+grades[i+1] : '+'}<br>`;
  });
  return div;
};
legend.addTo(map);
```

### How to cluster thousands of markers (plugin)
```html
<link rel="stylesheet" href="https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.css"/>
<link rel="stylesheet" href="https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.Default.css"/>
<script src="https://unpkg.com/leaflet.markercluster@1.5.3/dist/leaflet.markercluster.js"></script>
```
```javascript
const cluster = L.markerClusterGroup();
points.forEach(p => cluster.addLayer(L.marker([p.lat, p.lng])));
map.addLayer(cluster);
```

### How to add a base/overlay layer switcher
```javascript
const osm = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {attribution: '© OSM'});
const dark = L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {attribution: '© CARTO'});
osm.addTo(map);
L.control.layers({'Streets': osm, 'Dark': dark}, {'Stores': storeLayer}).addTo(map);
```

### How to handle clicks and read coordinates
```javascript
map.on('click', e => {
  L.popup().setLatLng(e.latlng).setContent(`${e.latlng.lat.toFixed(5)}, ${e.latlng.lng.toFixed(5)}`).openOn(map);
});
marker.on('click', e => console.log('marker clicked', e.target.getLatLng()));
```

## Do's and Don'ts

### ✅ Do
- **Always include `leaflet.css`** — without it tiles misalign and controls vanish.
- **Give the container an explicit height** (`#map { height: 400px }`).
- Use `[lat, lng]` order for Leaflet constructors; remember GeoJSON is `[lng, lat]`.
- Set `attribution` on tile layers — OSM's license requires it.
- Call `map.invalidateSize()` after showing a map that was hidden (tabs, modals).
- Use `L.circleMarker` (px radius) for fixed-size dots; `L.circle` (meter radius) for real-world distances.
- Cluster or use Canvas rendering (`preferCanvas: true`) for >1000 markers.

### ❌ Don't
- Don't swap lat/lng — points land in the ocean off Africa (0,0) or the wrong hemisphere.
- Don't add thousands of `L.marker` DOM icons; the DOM chokes — cluster instead.
- Don't forget `maxZoom` on the tile layer — panning past a provider's max shows gray tiles.
- Don't hard-code a tile provider that forbids heavy use (raw `tile.openstreetmap.org` is for light/dev use; use a commercial provider or your own tiles in production).
- Don't reuse one `L.icon` object expecting per-marker mutation — create fresh icons or use `divIcon` + CSS.

## Styling, Theming & Customization
- **Basemap theme**: swap the tile URL. Popular free/dark themes: CARTO `light_all` / `dark_all` / `voyager`, Stadia/Stamen `toner`, Esri `World_Imagery` (satellite).
- **Vector paint**: the Path options above (`color`, `fillColor`, `fillOpacity`, `weight`, `dashArray`).
- **CSS control over popups/tooltips/controls**: target `.leaflet-popup-content-wrapper`, `.leaflet-tooltip`, `.leaflet-control` in your stylesheet.
- **Custom markers via `divIcon`**: full CSS/HTML control — animate, add badges, use icon fonts.
- **`className` option** on any path/geoJSON layer lets you style it in CSS (stroke via `stroke`, fill via `fill`).

## Advanced Features
- **Panes** (`map.createPane`) control z-order stacking of layers.
- **Vector tiles** via Leaflet.VectorGrid for `.pbf` sources.
- **Canvas renderer** (`L.canvas()` / `preferCanvas: true`) for large vector datasets.
- **Custom CRS** via `L.CRS.Simple` (non-geographic image maps, game maps) or proj4leaflet for exotic projections.
- **Animations**: `flyTo`, `flyToBounds`, marker `slideTo` (plugin).

## Common Pitfalls & Troubleshooting
- **Blank/gray map**: missing CSS, zero-height container, or wrong tile URL/`maxZoom`.
- **Markers with no icon (broken image)**: bundlers mangle the default icon paths — either import the images explicitly or use `L.icon`/`divIcon`. Classic Webpack fix: re-point `L.Icon.Default` `iconUrl`s.
- **Map only renders top-left corner**: created while hidden → call `invalidateSize()` when shown.
- **Points in the wrong place**: lat/lng vs lng/lat swap.
- **CORS errors on tiles/GeoJSON**: the source must send `Access-Control-Allow-Origin` for cross-origin fetch.

## Best For / Avoid For
`location-maps`, `store-locators`, `real-estate`, `delivery-tracking`, `choropleth`, `geographic-data`, `mobile-maps` — Best for lightweight 2D interactive maps with no API key.
Avoid for: heavy WebGL vector rendering, tilted/3D views, millions of points, smooth vector-tile zoom → use MapLibre/Mapbox GL or deck.gl.

## See Also
- [mapbox-gl-js.md](mapbox-gl-js.md), [maplibre-gl-js.md](maplibre-gl-js.md) — WebGL vector alternatives
- [folium.md](folium.md) — Python wrapper that generates Leaflet maps
- [openlayers.md](openlayers.md) — heavier, projection-rich alternative
- [deck_gl.md](deck_gl.md) — large-scale GPU overlays on a Leaflet/Mapbox base
- [turf_js.md](turf_js.md) — client-side geospatial analysis to feed Leaflet layers
- `../use-case/geospatial-mapping.md`
