# HERE Maps — JS SDK for mapping, geocoding, routing, and traffic

HERE Maps API for JavaScript (the "HERE Maps API for JS", `mapsjs`) is the client SDK of the HERE Location Services platform. Beyond drawing raster/vector basemaps it exposes first-class **location services**: geocoding/search, routing (car/truck/transit/pedestrian with real traffic), isolines, matrix routing, and live traffic flow/incidents. Everything is created through an `H.service.Platform` object keyed by an API key. It is strongest for logistics, fleet, and navigation apps where truck routing, ETAs, and traffic matter.

**Current Version**: HERE Maps API for JS 3.1 (current)  **License**: Proprietary (HERE plans; free tier available)  **Runtime**: browser, API key required

## Official Resources & Documentation
- **Developer portal**: https://developer.here.com/
- **API for JS docs**: https://www.here.com/docs/bundle/maps-api-for-javascript-developer-guide/
- **API reference**: https://www.here.com/docs/bundle/maps-api-for-javascript-api-reference/
- **Examples**: https://www.here.com/docs/bundle/maps-api-for-javascript-developer-guide/page/topics/examples-overview.html
- **Get a key**: https://platform.here.com/ (free tier)

## Installation & Setup
HERE ships as separate script modules; include the ones you need + the CSS.
```html
<link rel="stylesheet" href="https://js.api.here.com/v3/3.1/mapsjs-ui.css"/>
<script src="https://js.api.here.com/v3/3.1/mapsjs-core.js"></script>
<script src="https://js.api.here.com/v3/3.1/mapsjs-service.js"></script>
<script src="https://js.api.here.com/v3/3.1/mapsjs-ui.js"></script>
<script src="https://js.api.here.com/v3/3.1/mapsjs-mapevents.js"></script>
```
```javascript
const platform = new H.service.Platform({ apikey: 'YOUR_HERE_API_KEY' });
```

## Core API Reference

### Platform + Map
```javascript
const platform = new H.service.Platform({ apikey: 'YOUR_API_KEY' });
const defaultLayers = platform.createDefaultLayers();

const map = new H.Map(
  document.getElementById('map'),
  defaultLayers.vector.normal.map,   // base layer
  { zoom: 10, center: { lat: 52.520008, lng: 13.404954 }, pixelRatio: window.devicePixelRatio || 1 }
);
// Interactivity + default UI (zoom, scale, layer switch)
const behavior = new H.mapevents.Behavior(new H.mapevents.MapEvents(map));
const ui = H.ui.UI.createDefault(map, defaultLayers);
window.addEventListener('resize', () => map.getViewPort().resize());
```
Base layer choices under `defaultLayers`: `vector.normal.map`, `raster.satellite.map`, `raster.terrain.map`, plus `.traffic` variants.

### Map objects (markers & shapes)
```javascript
// Default marker
map.addObject(new H.map.Marker({ lat: 52.52, lng: 13.40 }));

// Custom SVG/DOM marker
const icon = new H.map.Icon('<svg ...>...</svg>');
map.addObject(new H.map.Marker({ lat, lng }, { icon }));
map.addObject(new H.map.DomMarker({ lat, lng }, { icon: new H.map.DomIcon(divEl) }));

// Vector shapes
map.addObject(new H.map.Circle({ lat, lng }, 500, { style: { fillColor: 'rgba(0,128,255,.4)', strokeColor: '#08c', lineWidth: 2 } }));
const line = new H.geo.LineString(); line.pushPoint({lat:52.5,lng:13.4}); line.pushPoint({lat:52.6,lng:13.5});
map.addObject(new H.map.Polyline(line, { style: { strokeColor: '#e11', lineWidth: 4 } }));
map.addObject(new H.map.Polygon(ringLineString, { style: { fillColor: 'rgba(0,200,0,.3)' } }));

// Group many objects
const group = new H.map.Group(); group.addObjects([m1, m2]); map.addObject(group);
```

### Geocoding & search
```javascript
const service = platform.getSearchService();
service.geocode({ q: 'Berlin, Germany' }, result => {
  const pos = result.items[0].position;       // {lat, lng}
  map.setCenter(pos);
  map.addObject(new H.map.Marker(pos));
}, console.error);

service.reverseGeocode({ at: '52.5,13.4' }, r => console.log(r.items[0].address.label));
service.autosuggest({ q: 'coff', at: '52.5,13.4' }, r => console.log(r.items));
```

### Routing (v8)
```javascript
const router = platform.getRoutingService(null, 8);
router.calculateRoute({
  routingMode: 'fast',
  transportMode: 'truck',        // car | truck | pedestrian | bicycle | scooter
  origin: '52.520008,13.404954',
  destination: '52.530000,13.385000',
  return: 'polyline,summary'
}, result => {
  const section = result.routes[0].sections[0];
  const line = H.geo.LineString.fromFlexiblePolyline(section.polyline);
  map.addObject(new H.map.Polyline(line, { style: { lineWidth: 5, strokeColor: '#3170e7' } }));
  console.log(section.summary.duration, section.summary.length);
}, console.error);
```

### Traffic, isolines, matrix
```javascript
map.addLayer(defaultLayers.vector.normal.trafficincidents);   // incident overlay
// isoline (reachable area): platform.getRoutingService(null, 8) with 'isoline' request
// matrix routing: platform.getRoutingService for many-to-many ETAs (async job)
```

### Events
```javascript
map.addEventListener('tap', evt => {
  const coord = map.screenToGeo(evt.currentPointer.viewportX, evt.currentPointer.viewportY);
  console.log(coord.lat, coord.lng);
});
marker.addEventListener('tap', () => { /* open info bubble */
  ui.addBubble(new H.ui.InfoBubble({ lat, lng }, { content: 'Details' }));
});
```

## Supported Features
Basemaps (vector/raster: normal, satellite, terrain, traffic), markers (default/SVG/DOM), circles/polylines/polygons/rectangles, groups, InfoBubble UI, geocoding/reverse/autosuggest, routing (car/truck/transit/pedestrian/bicycle), isolines, matrix routing, live traffic flow + incidents, indoor maps, custom tile providers.

## How-To (worked recipes)

### How to set colors / style a shape or route
HERE map objects take a **`style`** object: `strokeColor`, `fillColor`, `lineWidth`, `lineDash`, `lineCap`. Colors are CSS strings (hex/rgba).
```javascript
const poly = new H.map.Polygon(ring, {
  style: { fillColor: 'rgba(255,0,0,0.35)', strokeColor: '#c00', lineWidth: 2, lineDash: [4, 3] }
});
map.addObject(poly);
poly.setStyle({ fillColor: 'rgba(0,128,0,0.4)' });   // restyle later
```
For data-driven coloring, compute the color per feature and set it in each object's `style`. To restyle the whole basemap, switch base layers (`defaultLayers.raster.satellite.map`) or apply a custom style via `H.map.Style`.

### How to geocode an address and center the map
```javascript
platform.getSearchService().geocode({ q: '1600 Amphitheatre Pkwy, CA' }, r => {
  const p = r.items[0].position; map.setCenter(p); map.setZoom(15);
  map.addObject(new H.map.Marker(p));
});
```

### How to draw a truck route with traffic-aware ETA
See the Routing snippet above with `transportMode: 'truck'` and `routingMode: 'fast'` (uses live traffic). `section.summary.duration` is seconds including traffic.

### How to add live traffic
```javascript
map.addLayer(defaultLayers.vector.normal.traffic);            // flow
map.addLayer(defaultLayers.vector.normal.trafficincidents);   // incidents
```

### How to show an isoline (reachable area) around a point
```javascript
const router = platform.getRoutingService(null, 8);
router.calculateIsoline({
  transportMode: 'car',
  origin: '52.52,13.40',
  range: { type: 'time', values: [600] },   // 10 minutes; or type:'distance' in metres
  rangeType: 'time'
}, result => {
  const iso = result.isolines[0];
  const line = H.geo.LineString.fromFlexiblePolyline(iso.polygons[0].outer);
  map.addObject(new H.map.Polygon(line, { style: { fillColor: 'rgba(0,120,255,0.25)', strokeColor: '#06c' } }));
}, console.error);
```

### How to open an InfoBubble popup on marker tap
```javascript
const bubble = new H.ui.InfoBubble({ lat: 52.52, lng: 13.40 }, { content: '<b>Berlin</b><br>Details here' });
marker.addEventListener('tap', evt => {
  bubble.setPosition(evt.target.getGeometry());
  ui.addBubble(bubble);            // ui = H.ui.UI.createDefault(...)
});
```

### How to cluster many markers
```javascript
const dataPoints = coords.map(c => new H.clustering.DataPoint(c.lat, c.lng));
const clusteredProvider = new H.clustering.Provider(dataPoints, {
  clusteringOptions: { eps: 32, minWeight: 2 }
});
map.addLayer(new H.map.layer.ObjectLayer(clusteredProvider));
```

## Do's and Don'ts

### ✅ Do
- Include **all** required `mapsjs-*` modules (core, service, ui, mapevents) + `mapsjs-ui.css`.
- Use `H.clustering.Provider` for large marker sets instead of thousands of `H.map.Marker` objects.
- Attach `H.mapevents.Behavior` and `H.ui.UI.createDefault` or the map won't pan/zoom or show controls.
- Call `map.getViewPort().resize()` on container resize.
- Use `{ lat, lng }` objects for coordinates (HERE's format), and `'lat,lng'` strings for routing endpoints.
- Use routing **v8** (`getRoutingService(null, 8)`); v7 is legacy.

### ❌ Don't
- Don't forget `mapsjs-mapevents.js` — the map renders but is frozen (no interaction).
- Don't decode route geometry manually — use `H.geo.LineString.fromFlexiblePolyline(section.polyline)`.
- Don't expose an unrestricted API key in client code — restrict by domain in the HERE portal.
- Don't confuse HERE's `{lat, lng}` object convention with GeoJSON `[lng, lat]` arrays.
- Don't mix v3.0 and v3.1 script URLs.

## Styling, Theming & Customization
- **Object style**: `style` object (`strokeColor`, `fillColor`, `lineWidth`, `lineDash`).
- **Basemap theme**: pick a base layer (`vector.normal.map`, `raster.satellite.map`, `raster.terrain.map`) or apply a custom vector style with `H.map.Style` (YAML/JSON style config).
- **Custom markers**: `H.map.Icon` (SVG/bitmap) or `H.map.DomIcon` (HTML/CSS).
- **UI**: `H.ui.UI.createDefault` gives zoom/scale/mapsettings; add `InfoBubble`s for popups.

## Advanced Features
- Truck routing with vehicle dimensions/hazmat restrictions.
- Isoline (reachability) and matrix routing (bulk ETAs).
- Public transit routing and departures.
- Fleet telematics, geofencing, indoor maps (venues).
- Custom tile providers via `H.map.provider.ImageTileProvider`.

## Common Pitfalls & Troubleshooting
- **Map frozen / no controls**: missing `mapsjs-mapevents.js`/`mapsjs-ui.js` or Behavior/UI not created.
- **401/403**: bad/restricted API key or wrong project.
- **Route line missing**: forgot to decode the flexible polyline, or requested no `polyline` in `return`.
- **Blurry map on retina**: set `pixelRatio` on the `H.Map` options.
- **Coordinates wrong**: passed `[lng,lat]` array instead of `{lat,lng}` object.

## Best For / Avoid For
`logistics`, `fleet`, `truck-routing`, `traffic`, `transit`, `geocoding`, `navigation` — Best for enterprise location services where routing, traffic, and ETAs are central.
Avoid for: quick open-data maps (Leaflet/MapLibre), token-free requirements, heavy custom WebGL data viz (deck.gl).

## See Also
- [google-maps-api.md](google-maps-api.md) — comparable proprietary platform with routing/places
- [mapbox-gl-js.md](mapbox-gl-js.md) — vector styling + directions alternative
- [leaflet_js.md](leaflet_js.md), [maplibre-gl-js.md](maplibre-gl-js.md) — open-source basemap alternatives
- `../use-case/geospatial-mapping.md`
