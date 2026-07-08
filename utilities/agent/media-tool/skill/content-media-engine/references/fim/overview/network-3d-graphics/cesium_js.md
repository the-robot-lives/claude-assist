# Cesium.js

## What
Cesium.js is a JavaScript library for rendering 3D globes and maps with accurate terrain, imagery layers, and time-dynamic geospatial visualization. It renders an interactive WebGL globe with entities, 3D models, and 3D Tiles. Primary consumer is browser JavaScript.

## How
- The LLM emits JavaScript that sets a `Cesium.Ion.defaultAccessToken`, creates a `Cesium.Viewer('cesiumContainer', options)`, adds terrain/buildings (`createWorldTerrain`, `createOsmBuildings`), flies the camera (`viewer.camera.flyTo` with `Cartesian3.fromDegrees`), and adds entities (points, labels, glTF models).
- Turned into a viewable artifact via npm (`npm install cesium`) or CDN includes of the release `widgets.css` and `Cesium.js`, mounted into a container element.
- Typical final artifact: an interactive WebGL 3D globe/map.

## Why
- Reach for Cesium.js when the visualization is fundamentally geospatial and global: geospatial data visualization, flight tracking, weather/climate visualization, urban planning, and satellite imagery analysis. Strengths are accurate terrain, time-dynamic visualization, massive-dataset support, built-in geocoding/imagery, and 3D Tiles for city-scale models.
- Limitations: requires an access token for full features, a large (10MB+) library, a complex API for simple use cases, and heavy performance cost for basic maps.
- Versus general 3D engines like [[three_js]] / [[babylon_js]] — Cesium is purpose-built for a georeferenced globe rather than an arbitrary 3D scene.

## Source
- Solution reference: `fim/solution/cesium_js.md`
