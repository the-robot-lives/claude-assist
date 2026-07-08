# Google Maps JavaScript API — Maps, markers, places, directions, styling

The Google Maps JavaScript API embeds Google's basemap and location services in a web page: interactive maps, markers/info windows, geocoding, Places (search/autocomplete/details), Directions/Distance Matrix, Street View, drawing tools, and heatmaps. Modern usage loads libraries dynamically and prefers the newer **`AdvancedMarkerElement`** (from the `marker` library) over the legacy `Marker`. Styling is done with **cloud-based Map Styles** (a Map ID) or, for older maps, inline `styles` JSON. Requires an API key and billing enabled.

**Current Version**: Maps JS API v3 (`weekly`/`quarterly` channels)  **License**: Proprietary (Google Maps Platform; usage-billed)  **Runtime**: browser, API key + billing required

## Official Resources & Documentation
- **Docs**: https://developers.google.com/maps/documentation/javascript
- **Reference**: https://developers.google.com/maps/documentation/javascript/reference
- **Examples**: https://developers.google.com/maps/documentation/javascript/examples
- **Cloud styling / Map IDs**: https://developers.google.com/maps/documentation/javascript/cloud-based-map-styling
- **Get a key**: https://console.cloud.google.com/apis/credentials

## Installation & Setup

### Dynamic library loader (recommended, current)
```html
<script>
  (g=>{/* official bootstrap loader */ var h,a,k,p="The Google Maps JavaScript API",c="google",l="importLibrary",q="__ib__",m=document,b=window;b=b[c]||(b[c]={});var d=b.maps||(b.maps={}),r=new Set,e=new URLSearchParams,u=()=>h||(h=new Promise(async(f,n)=>{await (a=m.createElement("script"));e.set("libraries",[...r]+"");for(k in g)e.set(k.replace(/[A-Z]/g,t=>"_"+t[0].toLowerCase()),g[k]);e.set("callback",c+".maps."+q);a.src=`https://maps.${c}apis.com/maps/api/js?`+e;d[q]=f;a.onerror=()=>h=n(Error(p+" could not load."));a.nonce=m.querySelector("script[nonce]")?.nonce||"";m.head.append(a)}));d[l]?console.warn(p+" only loads once. Ignoring:",g):d[l]=(f,...n)=>r.add(f)&&u().then(()=>d[l](f,...n))})({
    key: "YOUR_API_KEY", v: "weekly"
  });
</script>
```
```javascript
const { Map } = await google.maps.importLibrary('maps');
const { AdvancedMarkerElement } = await google.maps.importLibrary('marker');
```

### Classic script tag (still works)
```html
<script async src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY&libraries=places,marker&callback=initMap"></script>
```
Libraries: `maps`, `marker`, `places`, `geometry`, `drawing`, `visualization`, `routes`.

## Core API Reference

### Map
```javascript
const map = new google.maps.Map(document.getElementById('map'), {
  center: { lat: 37.7749, lng: -122.4194 },   // {lat, lng} objects
  zoom: 12,
  mapId: 'YOUR_MAP_ID',        // required for AdvancedMarkerElement & cloud styling
  mapTypeId: 'roadmap',        // roadmap | satellite | hybrid | terrain
  disableDefaultUI: false
});
```

### Markers
Modern (`marker` library, needs a `mapId`):
```javascript
const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary('marker');
const pin = new PinElement({ background: '#e11', borderColor: '#900', glyphColor: '#fff' });
const marker = new AdvancedMarkerElement({ map, position: { lat: 37.77, lng: -122.41 }, title: 'SF', content: pin.element });
// custom HTML content:
const el = document.createElement('div'); el.className = 'my-pin'; el.textContent = '📍';
new AdvancedMarkerElement({ map, position, content: el });
```
Legacy (deprecated but common):
```javascript
new google.maps.Marker({ position: { lat, lng }, map, title: 'SF', icon: 'icon.png' });
```

### Info windows
```javascript
const info = new google.maps.InfoWindow({ content: '<h3>Location</h3>' });
marker.addListener('click', () => info.open({ anchor: marker, map }));
```

### Shapes
```javascript
new google.maps.Circle({ map, center: { lat, lng }, radius: 500, fillColor: '#08c', fillOpacity: 0.3, strokeColor: '#06a', strokeWeight: 2 });
new google.maps.Polyline({ map, path: [{lat,lng}, {lat,lng}], strokeColor: '#e11', strokeWeight: 4 });
new google.maps.Polygon({ map, paths: [{lat,lng}, ...], fillColor: '#0a0', fillOpacity: 0.3 });
new google.maps.Rectangle({ map, bounds: { north, south, east, west } });
```

### Geocoding
```javascript
const geocoder = new google.maps.Geocoder();
geocoder.geocode({ address: 'Berlin, Germany' }, (results, status) => {
  if (status === 'OK') map.setCenter(results[0].geometry.location);
});
```

### Directions
```javascript
const svc = new google.maps.DirectionsService();
const renderer = new google.maps.DirectionsRenderer({ map });
svc.route({ origin: 'San Francisco, CA', destination: 'Los Angeles, CA', travelMode: google.maps.TravelMode.DRIVING },
  (result, status) => { if (status === 'OK') renderer.setDirections(result); });
```

### Places
```javascript
const { PlacesService } = await google.maps.importLibrary('places');
const service = new PlacesService(map);
service.nearbySearch({ location: { lat: 37.77, lng: -122.41 }, radius: 1000, type: 'restaurant' },
  (results, status) => { if (status === 'OK') results.forEach(p => console.log(p.name)); });
// Autocomplete widget
const ac = new google.maps.places.Autocomplete(document.getElementById('search'));
```

### Data layer (GeoJSON)
```javascript
map.data.loadGeoJson('data.geojson');
map.data.setStyle(feature => ({ fillColor: feature.getProperty('color'), strokeWeight: 1 }));
```

### Drawing & heatmap
```javascript
const dm = new google.maps.drawing.DrawingManager({ drawingControl: true,
  drawingControlOptions: { drawingModes: ['polygon', 'circle', 'rectangle'] } });
dm.setMap(map);
new google.maps.visualization.HeatmapLayer({ data: latLngArray, map, radius: 20 });
```

## Supported Features
Basemaps (roadmap/satellite/hybrid/terrain), AdvancedMarker/legacy Marker, InfoWindow, Circle/Polyline/Polygon/Rectangle, Data layer (GeoJSON), Geocoding, Places (nearby/text/details/autocomplete), Directions & Distance Matrix, Street View, Drawing, Heatmap, cloud-based Map Styles.

## How-To (worked recipes)

### How to set colors / style the map and features
Two layers of styling:
**(1) Basemap theme** — use cloud-based Map Styles via a **Map ID** (configure in Cloud Console, reference with `mapId`). Legacy inline JSON styling:
```javascript
const map = new google.maps.Map(el, { center, zoom, styles: [
  { elementType: 'geometry', stylers: [{ color: '#242f3e' }] },
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#17263c' }] },
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#38414e' }] },
  { featureType: 'poi', stylers: [{ visibility: 'off' }] }
]});
```
Note: inline `styles` is ignored when a `mapId` is set (cloud styling takes over).
**(2) Feature color** — set `fillColor`/`strokeColor` on shapes, or a `setStyle` function on the Data layer:
```javascript
map.data.setStyle(f => ({ fillColor: f.getProperty('value') > 50 ? '#e31a1c' : '#fd8d3c', fillOpacity: 0.7, strokeWeight: 1 }));
```

### How to add a marker with an info window
See Markers + Info windows above; combine for a clickable pin with a popup card.

### How to draw driving directions between two places
See Directions above — `DirectionsService.route()` + `DirectionsRenderer` draws the polyline and can populate a panel with `renderer.setPanel(el)`.

### How to add address autocomplete
```javascript
const ac = new google.maps.places.Autocomplete(document.getElementById('search'), { fields: ['geometry', 'name'] });
ac.addListener('place_changed', () => { const p = ac.getPlace(); if (p.geometry) map.setCenter(p.geometry.location); });
```

### How to cluster many markers
Use the official `@googlemaps/markerclusterer` library.
```javascript
import { MarkerClusterer } from '@googlemaps/markerclusterer';
const markers = places.map(p => new google.maps.marker.AdvancedMarkerElement({ position: p, map }));
new MarkerClusterer({ map, markers });
```

### How to load and style a GeoJSON overlay
```javascript
map.data.loadGeoJson('regions.geojson');
map.data.setStyle(f => ({
  fillColor: f.getProperty('value') > 50 ? '#e31a1c' : '#fd8d3c',
  fillOpacity: 0.6, strokeColor: '#fff', strokeWeight: 1
}));
map.data.addListener('click', e => new google.maps.InfoWindow({
  content: e.feature.getProperty('name'), position: e.latLng }).open(map));
```

## Do's and Don'ts

### ✅ Do
- Set a **`mapId`** to use `AdvancedMarkerElement` and cloud styling.
- Load libraries with `importLibrary('marker'|'places'|...)` (or the `libraries=` param).
- Use `{ lat, lng }` object literals (or `new google.maps.LatLng(lat, lng)`).
- Restrict the API key by HTTP referrer and enable only the APIs you use.
- Prefer `AdvancedMarkerElement` — `google.maps.Marker` is deprecated.

### ❌ Don't
- Don't combine inline `styles` with a `mapId` — cloud styling wins and inline is ignored.
- Don't use `AdvancedMarkerElement` without a `mapId` — it won't render.
- Don't ship an unrestricted key; billing abuse and quota exhaustion follow.
- Don't pass `[lng, lat]` arrays — Google uses `{lat, lng}` objects (lat first).
- Don't forget billing must be enabled or every request 4xx's with `BillingNotEnabled`.

## Styling, Theming & Customization
- **Cloud Map Styles** (recommended): design in Cloud Console, apply via `mapId`; change themes without code deploys.
- **Legacy inline `styles`**: array of `{ featureType, elementType, stylers: [{ color | visibility | lightness | saturation }] }`.
- **Feature styling**: shape color props; `map.data.setStyle()` for GeoJSON.
- **Custom markers**: `PinElement` (background/border/glyph colors) or arbitrary HTML via `AdvancedMarkerElement.content`.
- **Map types**: `roadmap`, `satellite`, `hybrid`, `terrain`.

## Advanced Features
- Street View (`StreetViewPanorama`).
- Distance Matrix (bulk origin→destination times) and Routes API.
- WebGL overlays (`WebGLOverlayView`) and vector maps with tilt/rotation (`mapId` + vector rendering) — integrate deck.gl via `GoogleMapsOverlay`.
- Heatmap layer (`visualization` library).
- Places details, photos, reviews; autocomplete/session tokens for billing efficiency.

## Common Pitfalls & Troubleshooting
- **`AdvancedMarkerElement` invisible**: no `mapId`, or `marker` library not loaded.
- **Gray map / "For development purposes only" watermark**: key missing, referrer-blocked, or billing off.
- **Inline styles ignored**: a `mapId` is set (use cloud styling instead).
- **`google is not defined`**: script/loader hasn't resolved — await `importLibrary` or use the `callback`.
- **Quota/`OVER_QUERY_LIMIT`**: unthrottled Places/Directions calls; add caching + session tokens.

## Best For / Avoid For
`places`, `directions`, `geocoding`, `street-view`, `autocomplete`, `familiar-basemap`, `business-locators` — Best when you need Google's data (POIs, traffic, transit, Street View) and users expect the Google Maps look.
Avoid for: token-free/self-hosted needs (MapLibre/Leaflet), heavy custom WebGL big-data viz (deck.gl), cost-sensitive high-volume tile serving.

## See Also
- [here-maps.md](here-maps.md) — comparable proprietary platform (strong routing/traffic)
- [mapbox-gl-js.md](mapbox-gl-js.md) — vector styling + directions alternative
- [leaflet_js.md](leaflet_js.md), [maplibre-gl-js.md](maplibre-gl-js.md) — open-source alternatives
- [deck_gl.md](deck_gl.md) — GPU overlays via GoogleMapsOverlay
- `../use-case/geospatial-mapping.md`
