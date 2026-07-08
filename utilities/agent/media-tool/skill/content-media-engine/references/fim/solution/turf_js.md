# Turf.js — Client-side geospatial analysis for GeoJSON

Turf.js is a modular JavaScript library of ~100+ geospatial operations that run entirely in the browser or Node — no server, no dependencies. Everything speaks **GeoJSON** in, GeoJSON out: measure distances/areas, buffer, union/intersect, point-in-polygon, nearest, bbox, centroid, transform (rotate/scale/translate), classify, interpolate, and build helper geometries. It is the analysis companion to renderers like Leaflet/Mapbox/MapLibre/deck.gl — Turf computes the shapes, the map library draws them.

**Current Version**: @turf/turf 7.x (current major)  **License**: MIT  **Runtime**: browser + Node, zero dependencies, tree-shakeable

## Official Resources & Documentation
- **Docs (all functions)**: https://turfjs.org/docs/
- **Site**: https://turfjs.org/
- **GitHub**: https://github.com/Turfjs/turf
- **npm**: https://www.npmjs.com/package/@turf/turf

## Installation & Setup

### npm (umbrella or per-module for smaller bundles)
```bash
npm install @turf/turf            # everything
npm install @turf/distance @turf/buffer @turf/helpers   # only what you use
```
```javascript
import * as turf from '@turf/turf';               // umbrella
import { point, distance } from '@turf/turf';     // named
// per-module:
import distance from '@turf/distance';
import { point } from '@turf/helpers';
```

### CDN
```html
<script src="https://cdn.jsdelivr.net/npm/@turf/turf@7/turf.min.js"></script>
<!-- global `turf` -->
```

## Core API Reference

Turf functions take GeoJSON `Feature`/`Geometry`/`FeatureCollection` (coordinates in `[lng, lat]`) and options objects. Most measurement functions accept `{ units: 'kilometers' | 'miles' | 'meters' | 'degrees' | 'radians' }` (default kilometers).

### Helpers (build GeoJSON)
```javascript
turf.point([-75.34, 39.98]);
turf.lineString([[-75, 39], [-75.5, 39.5]]);
turf.polygon([[[0,0],[0,10],[10,10],[10,0],[0,0]]]);   // first ring closed
turf.multiPoint([...]); turf.featureCollection([f1, f2]);
turf.point([lng, lat], { name: 'A' });                 // 2nd arg = properties
```

### Measurement
```javascript
turf.distance(from, to, { units: 'miles' });   // point-to-point
turf.area(polygon);                              // square meters
turf.length(lineString, { units: 'kilometers' });
turf.bbox(feature);                              // [minX, minY, maxX, maxY]
turf.center(fc); turf.centroid(polygon); turf.centerOfMass(polygon);
turf.along(line, 5, { units: 'km' });            // point 5km along a line
turf.bearing(pt1, pt2); turf.midpoint(pt1, pt2);
```

### Transformation
```javascript
turf.buffer(feature, 50, { units: 'kilometers' });   // NOTE: returns undefined for empty input
turf.simplify(line, { tolerance: 0.01, highQuality: false });
turf.union(turf.featureCollection([polyA, polyB]));  // v7: takes a FeatureCollection
turf.intersect(turf.featureCollection([polyA, polyB]));
turf.difference(turf.featureCollection([polyA, polyB]));
turf.dissolve(fc, { propertyName: 'zone' });
turf.transformRotate(poly, 45, { pivot: [lng, lat] });
turf.transformScale(poly, 2); turf.transformTranslate(poly, 10, 35);
turf.convex(fc); turf.concave(fc, { maxEdge: 1 });
turf.bboxClip(feature, bbox); turf.voronoi(points, { bbox });
```
**v7 breaking change**: `union`/`intersect`/`difference` now accept a single `FeatureCollection` of two polygons, not two positional args.

### Boolean / spatial predicates
```javascript
turf.booleanPointInPolygon(pt, poly);
turf.booleanIntersects(a, b); turf.booleanContains(a, b);
turf.booleanWithin(a, b); turf.booleanOverlap(a, b);
turf.booleanEqual(a, b); turf.booleanCrosses(a, b);
```

### Joins / classification / aggregation
```javascript
turf.tag(points, polygons, 'zone_id', 'zone');       // stamp polygon field onto points
turf.nearestPoint(target, pointsFC);
turf.pointsWithinPolygon(points, polygons);
turf.collect(polygons, points, 'value', 'values');   // gather point values into polygons
turf.clustersKmeans(points, { numberOfClusters: 5 });
turf.clustersDbscan(points, 1, { units: 'km' });
```

### Interpolation / grids
```javascript
turf.interpolate(controlPoints, 1, { gridType: 'hex', property: 'value', units: 'km' });
turf.isobands(pointGrid, [0, 10, 20], { zProperty: 'value' });
turf.hexGrid(bbox, 5, { units: 'km' }); turf.pointGrid(bbox, 1, { units: 'km' });
turf.tin(points, 'value');   // triangulated irregular network
```

### Random / sampling
```javascript
turf.randomPoint(30, { bbox: [0, 0, 10, 10] });
turf.randomPolygon(5, { bbox });
turf.sample(fc, 10);
```

## Supported Operation Categories
Measurement, coordinate mutation, transformation, feature conversion, misc, helper, data (random/sample), interpolation, joins, grids, classification, aggregation, meta (coordinate iteration), booleans, unit conversion. All GeoJSON-based.

## How-To (worked recipes)

### How to set colors / style analysis results on a map
Turf produces geometry; **color it where you render it**. Compute a value with Turf, then map value→color in Leaflet/Mapbox. Example: buffer + choropleth by area.
```javascript
const buffered = turf.buffer(turf.point([-90.5, 35.5]), 50, { units: 'kilometers' });
const areaKm2 = turf.area(buffered) / 1e6;
function ramp(v){ return v > 8000 ? '#800026' : v > 4000 ? '#e31a1c' : '#fd8d3c'; }

// Leaflet:
L.geoJSON(buffered, { style: { fillColor: ramp(areaKm2), color: '#fff', weight: 1, fillOpacity: 0.6 } }).addTo(map);
// Mapbox/MapLibre: add buffered as a geojson source, set paint 'fill-color' by a property you attach.
```
Attach the computed metric as a property so a data-driven paint expression can read it:
```javascript
buffered.properties = { areaKm2 };
```

### How to find which points fall inside a polygon
```javascript
const inside = turf.pointsWithinPolygon(pointsFC, polygonsFC);   // FeatureCollection of matches
// or single check:
const isIn = turf.booleanPointInPolygon(turf.point([-77, 44]), poly);
```

### How to measure a route and drop a marker at its midpoint
```javascript
const route = turf.lineString(coords);
const km = turf.length(route, { units: 'kilometers' });
const mid = turf.along(route, km / 2, { units: 'kilometers' });   // GeoJSON point
```

### How to build a hexbin heatmap from scattered points
```javascript
const bbox = turf.bbox(pointsFC);
const grid = turf.hexGrid(bbox, 2, { units: 'km' });
const counts = grid.features.map(hex => ({
  ...hex,
  properties: { n: turf.pointsWithinPolygon(pointsFC, turf.featureCollection([hex])).features.length }
}));
// render counts, color by properties.n
```

### How to build a merged service area from multiple buffers
```javascript
const buffers = stores.features.map(s => turf.buffer(s, 2, { units: 'kilometers' }));
let area = buffers[0];
for (let i = 1; i < buffers.length; i++) {
  area = turf.union(turf.featureCollection([area, buffers[i]]));   // v7 FeatureCollection input
}
// `area` = single (multi)polygon covering everything within 2km of any store
```

### How to snap a point to the nearest line and split a route
```javascript
const snapped = turf.nearestPointOnLine(routeLine, turf.point([lng, lat]), { units: 'km' });
const before = turf.lineSlice(turf.point(routeLine.geometry.coordinates[0]), snapped, routeLine);
```

## Do's and Don'ts

### ✅ Do
- Use **`[lng, lat]`** coordinate order (GeoJSON standard) everywhere.
- Pass explicit `{ units: ... }` on measurement/buffer calls — default is kilometers, easy to misread.
- Import per-module (`@turf/distance`) in bundled apps to keep size down.
- In v7, wrap the two polygons in a `featureCollection` for `union`/`intersect`/`difference`.
- Check for `undefined` returns from `intersect`/`buffer` (no overlap / empty input).

### ❌ Don't
- Don't feed `[lat, lng]` — every result will be wrong.
- Don't call v6-style `turf.union(a, b)` on v7 — it expects one FeatureCollection now.
- Don't run heavy overlay/interpolation on huge datasets on the main thread — use a Web Worker.
- Don't assume planar math on lat/lng gives true areas over large extents — Turf uses spherical measures, but very large/irregular polygons still need care.
- Don't mutate input features unless using the `-mutate` variants; most functions return new GeoJSON.

## Styling, Theming & Customization
Turf has **no rendering or styling** of its own — it is pure geometry/analysis. Styling happens in the renderer:
- **Leaflet**: `style`/`pointToLayer` on `L.geoJSON`.
- **Mapbox/MapLibre**: add Turf output as a `geojson` source, style with `paint` expressions on attached properties.
- **deck.gl**: feed Turf GeoJSON to a `GeoJsonLayer` with accessor colors.
Attach computed metrics as GeoJSON `properties` so data-driven color ramps can read them.

## Advanced Features
- Clustering (`clustersKmeans`, `clustersDbscan`).
- Interpolation surfaces (`interpolate`, `tin`, `isobands`, `isolines`).
- Voronoi/Delaunay, convex/concave hulls, grids (hex/square/triangle/point).
- Coordinate meta helpers (`coordEach`, `featureEach`, `propReduce`) for custom iteration.
- Combine with a Web Worker for non-blocking heavy computation.

## Common Pitfalls & Troubleshooting
- **Wrong distances/areas**: lat/lng swapped, or wrong `units`.
- **`union is not a function` / arg errors**: v6→v7 API change (FeatureCollection input).
- **`undefined` result**: `intersect`/`difference` with non-overlapping polygons, or `buffer` of empty geometry.
- **Self-intersection errors** in overlays: clean geometry first (rewind rings, `turf.cleanCoords`).
- **Slow UI**: large `interpolate`/overlay on main thread — offload to a worker.

## Best For / Avoid For
`geospatial-analysis`, `distance-area`, `buffer`, `point-in-polygon`, `hexbin`, `spatial-join`, `client-side-gis` — Best for in-browser/Node GeoJSON math feeding a map renderer.
Avoid for: rendering/basemaps (pair with Leaflet/Mapbox), huge server-scale analysis (use PostGIS/GeoPandas), raster operations.

## See Also
- [leaflet_js.md](leaflet_js.md), [mapbox-gl-js.md](mapbox-gl-js.md), [maplibre-gl-js.md](maplibre-gl-js.md) — render Turf output
- [deck_gl.md](deck_gl.md) — GPU rendering of computed GeoJSON
- [geopandas.md](geopandas.md) — the Python/server analog
- `../use-case/geospatial-mapping.md`
