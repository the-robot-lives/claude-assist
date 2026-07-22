# CesiumJS — 3D globes, maps & time-dynamic geospatial

CesiumJS is an open-source WebGL library for world-scale 3D geospatial visualization: a photorealistic ellipsoidal globe with terrain, imagery layers, 3D Tiles (city meshes, point clouds, photogrammetry), vector data, and a built-in **clock/timeline** for time-dynamic data (flights, satellites, sensors). Positions are real-world coordinates (WGS84 lon/lat/height), not scene units. It's the standard for aviation, defense, smart-city, and satellite-tracking apps.

**Current Version**: 1.12x+ (npm `cesium`, "current major" ~1.12x, monthly) **License**: Apache-2.0 (library). Cesium ion assets (world terrain/imagery/3D buildings) need a free ion access token. **Bundle/Runtime**: ~10 MB (full build incl. workers/assets); served with a static asset base URL.

## Official Resources & Documentation
- **Docs / API**: https://cesium.com/learn/cesiumjs/ref-doc/
- **Sandcastle** (live example gallery — best reference): https://sandcastle.cesium.com/
- **Site**: https://cesium.com/platform/cesiumjs/
- **Repo**: https://github.com/CesiumGS/cesium
- **npm**: https://www.npmjs.com/package/cesium
- **ion (tokens, tilesets)**: https://cesium.com/ion/
- **CZML guide**: https://github.com/CesiumGS/cesium/wiki/CZML-Guide

## Installation & Setup

### Package manager
```bash
npm install cesium
```
CesiumJS ships web workers, WASM, and static assets. Your bundler must copy `node_modules/cesium/Build/Cesium/` to a served path and set `window.CESIUM_BASE_URL`. Vite: `vite-plugin-cesium`. Webpack: `copy-webpack-plugin` + `CESIUM_BASE_URL` define.

### CDN
```html
<link href="https://cesium.com/downloads/cesiumjs/releases/1.120/Build/Cesium/Widgets/widgets.css" rel="stylesheet">
<script src="https://cesium.com/downloads/cesiumjs/releases/1.120/Build/Cesium/Cesium.js"></script>
```

### Access token
```javascript
Cesium.Ion.defaultAccessToken = 'YOUR_ION_TOKEN';  // required for ion terrain/imagery/OSM buildings
```

## Core Syntax / API Reference

### The Viewer
`Viewer` is the all-in-one widget: globe, camera, timeline, animation clock, base-layer picker, scene.
```javascript
const viewer = new Cesium.Viewer('cesiumContainer', {
  terrain: Cesium.Terrain.fromWorldTerrain(),   // async world terrain
  baseLayerPicker: false, geocoder: false, homeButton: false,
  sceneModePicker: false, navigationHelpButton: false, timeline: true, animation: true,
});
const scene  = viewer.scene;
const camera = viewer.camera;
const clock  = viewer.clock;
```
For a lighter, widget-free setup use `new Cesium.CesiumWidget(container)`.

### Positions & coordinates
```javascript
Cesium.Cartesian3.fromDegrees(lon, lat, height);          // most common: lon/lat/meters
Cesium.Cartesian3.fromDegreesArray([lon1,lat1, lon2,lat2]); // polylines/polygons
Cesium.Cartographic.fromDegrees(lon, lat, height);        // radians internally
// Orientation via heading/pitch/roll:
Cesium.Transforms.headingPitchRollQuaternion(pos, new Cesium.HeadingPitchRoll(h, p, r));
```

### Entities (high-level, data-driven)
The Entity API is the recommended way to add graphics; one entity can carry point/label/billboard/model/polyline/polygon graphics.
```javascript
const e = viewer.entities.add({
  name: 'NYC',
  position: Cesium.Cartesian3.fromDegrees(-74.0066, 40.7128, 100),
  point: { pixelSize: 10, color: Cesium.Color.RED, outlineColor: Cesium.Color.WHITE, outlineWidth: 2 },
  label: { text: 'New York City', font: '14pt sans-serif',
           verticalOrigin: Cesium.VerticalOrigin.BOTTOM,
           pixelOffset: new Cesium.Cartesian2(0, -12) },
});

viewer.entities.add({                              // 3D model (glTF/GLB)
  position: Cesium.Cartesian3.fromDegrees(-74.01, 40.71, 0),
  model: { uri: 'aircraft.glb', scale: 4, minimumPixelSize: 64 },
});

viewer.entities.add({                              // extruded polygon (building footprint)
  polygon: {
    hierarchy: Cesium.Cartesian3.fromDegreesArray([-74.01,40.70, -74.00,40.70, -74.00,40.71]),
    height: 0, extrudedHeight: 120, material: Cesium.Color.CYAN.withAlpha(0.6),
  },
});

viewer.entities.add({                              // polyline (path/route)
  polyline: { positions: Cesium.Cartesian3.fromDegreesArray([-74.01,40.70, -73.99,40.73]),
              width: 3, material: Cesium.Color.YELLOW },
});
viewer.zoomTo(viewer.entities);
```
Entity graphics: `point`, `label`, `billboard`, `model`, `polyline`, `polygon`, `rectangle`, `ellipse`, `ellipsoid`, `box`, `cylinder`, `corridor`, `wall`, `path`.

### Imagery providers (basemaps / overlays)
```javascript
const layers = viewer.imageryLayers;
layers.addImageryProvider(new Cesium.UrlTemplateImageryProvider({
  url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
}));
Cesium.IonImageryProvider.fromAssetId(3);          // Bing/ion imagery
new Cesium.WebMapServiceImageryProvider({ url, layers });        // WMS
new Cesium.WebMapTileServiceImageryProvider({ url, layer, style, tileMatrixSetID }); // WMTS
new Cesium.ArcGisMapServerImageryProvider({ url });
```

### Terrain providers
```javascript
viewer.terrainProvider = await Cesium.createWorldTerrainAsync({ requestVertexNormals: true, requestWaterMask: true });
// or flat: new Cesium.EllipsoidTerrainProvider();
// custom quantized-mesh: await Cesium.CesiumTerrainProvider.fromUrl(url);
```

### 3D Tiles (city meshes, point clouds, photogrammetry)
```javascript
const tileset = await Cesium.Cesium3DTileset.fromIonAssetId(96188); // OSM Buildings
scene.primitives.add(tileset);
// or: await Cesium.Cesium3DTileset.fromUrl('tiles/tileset.json');
// style with 3D Tiles Styling language:
tileset.style = new Cesium.Cesium3DTileStyle({
  color: "color('white') * (${Height} > 100 ? color('red') : color('cyan'))",
  show: '${Height} > 0',
});
```

### Camera control
```javascript
viewer.camera.flyTo({
  destination: Cesium.Cartesian3.fromDegrees(-74.0066, 40.7128, 1500),
  orientation: { heading: Cesium.Math.toRadians(20), pitch: Cesium.Math.toRadians(-35), roll: 0 },
  duration: 3,
});
viewer.camera.setView({ destination });          // instant
viewer.zoomTo(entityOrTileset);
```

## Data Formats / Output Types
- **CZML** — Cesium's time-dynamic JSON scene description (positions, availability, interpolated paths).
- **GeoJSON / TopoJSON** — `Cesium.GeoJsonDataSource.load(url)`.
- **KML/KMZ** — `Cesium.KmlDataSource.load(url)`.
- **3D Tiles** (`.json` tileset) — b3dm/pnts/glTF; the scalable format for massive city data.
- **glTF/GLB** — individual 3D models via `model` graphics.
- **Imagery**: XYZ/TMS, WMS, WMTS, ArcGIS, Bing, ion, single tile.

## How-To

### How to add colors, materials & styling (mandatory styling recipe)
Color lives on each graphic's `material`/`color`. Cesium colors are `Cesium.Color` (0–1 RGBA); use `.fromCssColorString`, named constants, or `.withAlpha`. Materials can be solid, image, stripe, grid, or checkerboard.
```javascript
viewer.entities.add({
  polygon: {
    hierarchy: Cesium.Cartesian3.fromDegreesArray([-74.02,40.70, -74.00,40.70, -74.00,40.72]),
    material: Cesium.Color.fromCssColorString('#4f8cff').withAlpha(0.55),  // fill
    outline: true, outlineColor: Cesium.Color.WHITE, height: 0, extrudedHeight: 90,
  },
});
// Animated/patterned materials:
polyline.material = new Cesium.PolylineGlowMaterialProperty({ color: Cesium.Color.CYAN, glowPower: 0.2 });
polygon.material  = new Cesium.StripeMaterialProperty({ evenColor: Cesium.Color.WHITE, oddColor: Cesium.Color.BLACK });
// Globe/scene look:
scene.globe.enableLighting = true;             // sun-based day/night shading
scene.skyAtmosphere.show = true;
scene.fog.enabled = true;
```
For 3D Tiles use the **3D Tiles Styling** expression language (`tileset.style`) to color by feature property (height, type). Enable `scene.globe.enableLighting` and `skyAtmosphere` for a realistic look.

### How to visualize time-dynamic data with CZML
CZML positions can carry a time-tagged sample array; Cesium interpolates as the clock runs.
```javascript
const czml = [
  { id: 'document', name: 'flight', version: '1.0',
    clock: { interval: '2026-01-01T00:00:00Z/2026-01-01T01:00:00Z', currentTime: '2026-01-01T00:00:00Z', multiplier: 60 } },
  { id: 'plane',
    availability: '2026-01-01T00:00:00Z/2026-01-01T01:00:00Z',
    model: { gltf: 'plane.glb' },
    position: { epoch: '2026-01-01T00:00:00Z',
      cartographicDegrees: [ 0, -74.0, 40.7, 3000,  1800, -73.0, 41.0, 6000 ] }, // t,lon,lat,h,...
    path: { material: { solidColor: { color: { rgba: [255, 255, 0, 200] } } }, width: 2 } },
];
const ds = await Cesium.CzmlDataSource.load(czml);
viewer.dataSources.add(ds);
viewer.clock.shouldAnimate = true;
```
Programmatic time-dynamic position without CZML: `SampledPositionProperty`.
```javascript
const prop = new Cesium.SampledPositionProperty();
prop.addSample(Cesium.JulianDate.fromIso8601('2026-01-01T00:00:00Z'), Cesium.Cartesian3.fromDegrees(-74,40.7,3000));
prop.addSample(Cesium.JulianDate.fromIso8601('2026-01-01T00:30:00Z'), Cesium.Cartesian3.fromDegrees(-73,41,6000));
viewer.entities.add({ position: prop, model: { uri: 'plane.glb' },
  orientation: new Cesium.VelocityOrientationProperty(prop), path: {} });
```

### How to click/pick features
```javascript
const handler = new Cesium.ScreenSpaceEventHandler(scene.canvas);
handler.setInputAction((movement) => {
  const picked = scene.pick(movement.position);
  if (Cesium.defined(picked) && picked.id) console.log('Entity:', picked.id.name);
  if (Cesium.defined(picked) && picked instanceof Cesium.Cesium3DTileFeature)
    console.log('Building height:', picked.getProperty('Height'));
}, Cesium.ScreenSpaceEventType.LEFT_CLICK);
```

### How to load GeoJSON with styling
```javascript
const geo = await Cesium.GeoJsonDataSource.load('states.geojson', {
  stroke: Cesium.Color.HOTPINK, fill: Cesium.Color.PINK.withAlpha(0.4), strokeWidth: 2, clampToGround: true,
});
viewer.dataSources.add(geo);
```

## Do's and Don'ts

### ✅ Do
- Set `Cesium.Ion.defaultAccessToken` before using world terrain/imagery/OSM buildings.
- Use the **Entity API** for data; use **Primitive API** only when you need max performance/custom shaders.
- Use **3D Tiles** for large city/point-cloud data — never thousands of individual entities.
- Set `window.CESIUM_BASE_URL` and copy the `Build/Cesium` assets when bundling.
- Use the clock/timeline for anything time-varying instead of manual per-frame updates.

### ❌ Don't
- Don't pass scene units — positions are real lon/lat/height via `Cartesian3.fromDegrees`.
- Don't add 10k+ entities for dense data; performance collapses. Use tilesets/primitives/point primitives.
- Don't forget `.withAlpha()` for translucency; a bare `Color` is opaque and will z-fight the globe.
- Don't block on synchronous terrain — providers are async (`await createWorldTerrainAsync`).
- Don't ship without handling the ion token/quota for production.

## Styling, Theming & Customization
- **Globe/scene**: `scene.globe.enableLighting`, `skyAtmosphere`, `fog`, `scene.backgroundColor`, `globe.baseColor`.
- **Materials**: solid color, image, stripe, grid, checkerboard, `PolylineGlow`, `PolylineDash`, `PolylineArrow`.
- **3D Tiles styling**: expression language coloring by feature properties (`tileset.style`).
- **Scene modes**: `Scene3D`, `ColumbusView` (2.5D), `Scene2D` (`viewer.scene.morphTo2D()`).
- **Post-processing**: `scene.postProcessStages` (bloom, ambient occlusion, silhouette).

## Advanced Features
- **Clock & timeline**: `viewer.clock.multiplier`, `shouldAnimate`, `Clock.onTick`.
- **Entity clustering** for dense point sets (`dataSource.clustering`).
- **Custom shaders on 3D Tiles/models** via `CustomShader`.
- **Clamp-to-ground** for polylines/labels; `HeightReference.CLAMP_TO_GROUND`.
- **Geocoder / measurement / sensors** (some via Cesium ion / community plugins).
- **Terrain sampling**: `sampleTerrainMostDetailed` to snap points to elevation.

## Common Pitfalls & Troubleshooting
- **"An error occurred while rendering" / blank globe** — missing/invalid ion token, or `CESIUM_BASE_URL`/assets not served.
- **Widgets look broken/unstyled** — `widgets.css` not loaded.
- **Model tiny or upside down** — wrong `scale`, missing `minimumPixelSize`, or orientation/quaternion not set.
- **Everything at (0,0,0) / center of earth** — used raw x/y instead of `Cartesian3.fromDegrees`.
- **Terrain not showing** — provider still loading (async) or requestVertexNormals not set for lighting.
- **Poor performance** — too many entities; migrate to 3D Tiles/point primitives; enable request render mode (`viewer.scene.requestRenderMode = true`) for static scenes.
- **CORS** on imagery/models — remote sources need CORS headers.

## Integration Notes
- **Vite**: `vite-plugin-cesium`. **Webpack**: copy assets + `CESIUM_BASE_URL` define.
- **React**: `resium` provides React components over CesiumJS.
- **Request render mode** (`requestRenderMode: true`) drastically cuts power draw for non-animated scenes.

## Best For / Avoid For
`3d-globes`, `satellite-tracking`, `flight-paths`, `smart-city`, `terrain-visualization`, `time-dynamic-geo` — choose CesiumJS for accurate world-scale, terrain, 3D Tiles, and temporal data.
Avoid for: 2D slippy maps (use Leaflet/MapLibre — lighter), small non-geospatial 3D (three.js), or when the 10 MB payload/token overhead isn't justified.

## See Also
- `three_js.md`, `react-three-fiber.md` — general 3D (not geospatial)
- `webgl.md` — the layer CesiumJS renders through
- `../use-case/geospatial-mapping.md` — map/geo solution selection
- `../use-case/3d-graphics.md` — 3D solution selection
