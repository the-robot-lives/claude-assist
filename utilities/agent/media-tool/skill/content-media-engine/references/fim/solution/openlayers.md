# OpenLayers — Feature-rich mapping with deep projection support

OpenLayers (OL) is a mature, high-performance open-source mapping library built around a strict **Map → View → Layer → Source → Feature → Style** object model. It is the strongest choice when you need serious GIS capability in the browser: arbitrary projections via proj4, OGC services (WMS/WMTS/WFS), reprojection on the fly, precise vector editing/drawing, and mixed Canvas/WebGL rendering. Heavier and more verbose than Leaflet, but far more capable for cartographic and enterprise GIS work.

**Current Version**: ol 10.x (current major)  **License**: BSD-2-Clause  **Runtime**: Canvas + WebGL, no token required

## Official Resources & Documentation
- **Docs / API**: https://openlayers.org/en/latest/apidoc/
- **Examples**: https://openlayers.org/en/latest/examples/
- **Workshop/tutorials**: https://openlayers.org/workshop/
- **GitHub**: https://github.com/openlayers/openlayers
- **npm**: https://www.npmjs.com/package/ol

## Installation & Setup

### npm / bundler (tree-shakeable ES modules)
```bash
npm install ol
```
```javascript
import Map from 'ol/Map.js';
import View from 'ol/View.js';
import TileLayer from 'ol/layer/Tile.js';
import OSM from 'ol/source/OSM.js';
import 'ol/ol.css';   // REQUIRED for controls
```

### CDN (full build)
```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/ol@10/ol.css">
<script src="https://cdn.jsdelivr.net/npm/ol@10/dist/ol.js"></script>
<!-- global `ol` namespace: new ol.Map(...) -->
```

## Core API Reference

### Map + View
```javascript
const map = new Map({
  target: 'map',
  layers: [ new TileLayer({ source: new OSM() }) ],
  view: new View({
    center: [0, 0],   // in the VIEW projection (default EPSG:3857 metres, NOT lat/lng)
    zoom: 2,
    projection: 'EPSG:3857',
    minZoom: 0, maxZoom: 20
  })
});
```
Coordinates are in the view's projection. To use lon/lat input, transform:
```javascript
import { fromLonLat, toLonLat } from 'ol/proj.js';
view.setCenter(fromLonLat([-122.4, 37.8]));   // lon/lat → Web Mercator
```

### Layer types
- `ol/layer/Tile` — tiled raster (XYZ, OSM, WMTS, WMS-tiled)
- `ol/layer/Image` — single untiled image (ImageWMS, static image)
- `ol/layer/Vector` — features rendered on Canvas
- `ol/layer/VectorTile` — vector tiles (`.pbf`/MVT)
- `ol/layer/WebGLTile` — GPU raster (COG/GeoTIFF, hillshade)
- `ol/layer/Heatmap` — built-in heatmap of point features

### Source types
```javascript
import XYZ from 'ol/source/XYZ.js';
import VectorSource from 'ol/source/Vector.js';
import GeoJSON from 'ol/format/GeoJSON.js';
import TileWMS from 'ol/source/TileWMS.js';

new XYZ({ url: 'https://tile.example.com/{z}/{x}/{y}.png' });
new VectorSource({ url: 'data.geojson', format: new GeoJSON() });
new TileWMS({ url: 'https://wms.example.com/geoserver/wms', params: { LAYERS: 'workspace:layer', TILED: true } });
```
Formats: `GeoJSON`, `TopoJSON`, `KML`, `GPX`, `WKT`, `MVT`, `EsriJSON`, `WFS`.

### Vector layer + features
```javascript
const source = new VectorSource({ url: 'data.geojson', format: new GeoJSON() });
const vector = new VectorLayer({ source });
map.addLayer(vector);

// build a feature by hand
import Feature from 'ol/Feature.js';
import Point from 'ol/geom/Point.js';
const f = new Feature({ geometry: new Point(fromLonLat([-122.4, 37.8])), name: 'SF' });
source.addFeature(f);
```

### Styling — `ol/style`
```javascript
import { Style, Fill, Stroke, Circle as CircleStyle, Text, Icon } from 'ol/style.js';

const style = new Style({
  fill: new Fill({ color: 'rgba(255,0,0,0.4)' }),
  stroke: new Stroke({ color: '#c00', width: 2, lineDash: [4, 4] }),
  image: new CircleStyle({ radius: 6, fill: new Fill({ color: '#c00' }), stroke: new Stroke({ color: '#fff', width: 1 }) }),
  text: new Text({ text: 'label', fill: new Fill({ color: '#000' }), font: '12px sans-serif' })
});
vector.setStyle(style);
```

### Interactions & controls
```javascript
import Draw from 'ol/interaction/Draw.js';
import { Select, Modify, Snap } from 'ol/interaction.js';
import { ScaleLine, FullScreen, MousePosition } from 'ol/control.js';

map.addInteraction(new Draw({ source, type: 'Polygon' }));  // Point|LineString|Polygon|Circle
map.addInteraction(new Select());
map.addControl(new ScaleLine());
map.addControl(new FullScreen());
```

### Overlays (HTML popups)
```javascript
import Overlay from 'ol/Overlay.js';
const popup = new Overlay({ element: document.getElementById('popup'), positioning: 'bottom-center' });
map.addOverlay(popup);
map.on('click', e => {
  const feat = map.forEachFeatureAtPixel(e.pixel, f => f);
  if (feat) { popup.setPosition(e.coordinate); /* fill element HTML */ }
});
```

## Supported Layer/Source Types
Tile, Image, Vector, VectorTile, WebGLTile, Heatmap, Graticule layers. Sources: OSM, XYZ, WMTS, TileWMS/ImageWMS, VectorSource, VectorTile(MVT), GeoTIFF, Cluster, TileJSON, Stamen/CARTO via XYZ. Full OGC (WMS/WMTS/WFS) support and on-the-fly reprojection.

## How-To (worked recipes)

### How to set colors / style a layer
Static style (above). For **data-driven** styling, pass a style function that returns a `Style` per feature:
```javascript
function ramp(v) { return v > 100 ? '#800026' : v > 50 ? '#e31a1c' : v > 10 ? '#fd8d3c' : '#ffeda0'; }
vector.setStyle(feature => new Style({
  fill: new Fill({ color: ramp(feature.get('value')) }),
  stroke: new Stroke({ color: '#fff', width: 1 })
}));
```
WebGL vector styling uses a JSON expression style (`['interpolate', ['linear'], ['get','value'], ...]`) on `WebGLVectorLayer` for large datasets.

### How to reproject / handle a custom projection
```javascript
import { register } from 'ol/proj/proj4.js';
import proj4 from 'proj4';
proj4.defs('EPSG:27700', '+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +units=m +no_defs');
register(proj4);
const view = new View({ projection: 'EPSG:27700', center: [400000, 400000], zoom: 7 });
```

### How to add a WMS/WFS layer
```javascript
const wms = new TileLayer({ source: new TileWMS({
  url: 'https://ows.example.com/geoserver/wms',
  params: { LAYERS: 'topp:states', TILED: true }, serverType: 'geoserver' }) });
map.addLayer(wms);
```

### How to draw, modify, and snap features
```javascript
const select = new Select();
const modify = new Modify({ features: select.getFeatures() });
map.addInteraction(select);
map.addInteraction(modify);
map.addInteraction(new Snap({ source }));
```

## Do's and Don'ts

### ✅ Do
- Remember the **view projection** — default is EPSG:3857 (metres); wrap lon/lat with `fromLonLat`.
- Import `ol/ol.css` for controls to render correctly.
- Use tree-shakeable submodule imports (`import Map from 'ol/Map.js'`) to keep bundles small.
- Use a style **function** for per-feature/data-driven styling.
- Use `VectorTile`/`WebGLTile`/`WebGLVector` layers for large data, not plain `Vector`.

### ❌ Don't
- Don't pass `[lat, lng]` — OL coordinates are `[x, y]` = `[lon, lat]` after `fromLonLat`, and internal units are projected metres.
- Don't import the whole `ol` package as a namespace in bundled apps (defeats tree-shaking).
- Don't attach thousands of features to a plain Canvas `VectorLayer` and expect 60fps — cluster or go WebGL.
- Don't forget `serverType` on GeoServer/MapServer WMS (affects GetFeatureInfo/error parsing).
- Don't mutate a shared `Style` object per feature; return new/ cached styles from the style function.

## Styling, Theming & Customization
- **Vector**: `Style` with `Fill`/`Stroke`/`Circle`/`Icon`/`Text`; style functions for data-driven color ramps.
- **Basemap theme**: swap the tile source (OSM, CARTO light/dark via XYZ, satellite via XYZ/Esri).
- **Clustering**: wrap a `VectorSource` in `ol/source/Cluster` and style by `features.length`.
- **Labels**: the `text` member of a `Style` (`Text` with `font`, `offsetY`, `overflow`).
- **WebGL expression styles** for GPU color/size ramps at scale.

## Advanced Features
- On-the-fly reprojection between any registered CRS.
- `ol/source/GeoTIFF` + `WebGLTile` for Cloud-Optimized GeoTIFF and band math.
- Full drawing/editing stack: Draw, Modify, Snap, Translate, Select.
- Clustering, heatmaps, graticules, image/canvas layers.
- Export to PNG via `map.once('rendercomplete', ...)` + canvas toDataURL.

## Common Pitfalls & Troubleshooting
- **Map centered wrong / off-world**: coordinates not transformed to the view projection.
- **Controls unstyled**: missing `ol.css`.
- **GeoJSON not showing**: its CRS differs from the view — pass `format: new GeoJSON({ dataProjection: 'EPSG:4326', featureProjection: view.getProjection() })`.
- **Slow vector rendering**: too many Canvas features → cluster / WebGL.
- **WMS blank**: wrong `LAYERS`, projection mismatch, or missing `serverType`.

## Best For / Avoid For
`gis`, `projections`, `wms-wfs`, `vector-editing`, `cartography`, `enterprise-maps`, `geotiff` — Best for full-featured GIS, OGC services, custom CRS, and precise editing.
Avoid for: quick lightweight pins (Leaflet), token-based Mapbox styling ecosystems, GPU big-data point animation (deck.gl).

## See Also
- [leaflet_js.md](leaflet_js.md) — lighter, simpler alternative
- [maplibre-gl-js.md](maplibre-gl-js.md) — WebGL vector-tile alternative
- [mapbox-gl-js.md](mapbox-gl-js.md) — proprietary vector styling ecosystem
- [geopandas.md](geopandas.md) — server-side geospatial prep feeding OL
- [turf_js.md](turf_js.md) — client-side GeoJSON analysis
- `../use-case/geospatial-mapping.md`
