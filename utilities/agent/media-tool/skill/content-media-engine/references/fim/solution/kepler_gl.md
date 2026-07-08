# Kepler.gl — No-code, high-volume geospatial analytics UI

Kepler.gl is an open-source (by vis.gl / Uber) web application and React component for exploring large geospatial datasets through a point-and-click UI, powered by deck.gl + Mapbox/MapLibre. You feed it tabular or GeoJSON data and it auto-detects columns, letting users add layers (points, arcs, hexbins, heatmaps, trips, polygons), apply filters, animate over time, and tune styling — all without code. State lives in a serializable **config** object, so an agent can reproduce a saved view programmatically. It ships both as a Redux-connected React component and as a **Jupyter/Python widget** (`keplergl`).

**Current Version**: kepler.gl 3.x (current major)  **License**: MIT  **Runtime**: React + Redux + deck.gl (WebGL); base map token optional (MapLibre styles work token-free)

## Official Resources & Documentation
- **Site / demo**: https://kepler.gl/ , https://kepler.gl/demo
- **Docs**: https://docs.kepler.gl/
- **GitHub**: https://github.com/keplergl/kepler.gl
- **npm**: https://www.npmjs.com/package/@kepler.gl/components
- **Python (Jupyter) docs**: https://docs.kepler.gl/docs/keplergl-jupyter

## Installation & Setup

### React
```bash
npm install kepler.gl redux react-redux redux-actions styled-components
```
```javascript
import KeplerGl from '@kepler.gl/components';
import keplerGlReducer from '@kepler.gl/reducers';
```

### Python / Jupyter
```bash
pip install keplergl
```
```python
from keplergl import KeplerGl
m = KeplerGl(height=600)
m.add_data(data=df, name='trips')     # pandas DataFrame or GeoDataFrame or GeoJSON
m                                      # renders inline in Jupyter
m.save_to_html(file_name='map.html')   # standalone export
```

## Core API Reference

### React component
```jsx
<KeplerGl
  id="map"
  mapboxApiAccessToken={MAPBOX_TOKEN}   // optional; omit for MapLibre/no-token styles
  width={window.innerWidth}
  height={window.innerHeight}
/>
```
Kepler is Redux-driven — mount its reducer and dispatch actions to add data/config.

### Redux store
```javascript
import { createStore, combineReducers, applyMiddleware } from 'redux';
import { taskMiddleware } from 'react-palm/tasks';
import keplerGlReducer from '@kepler.gl/reducers';

const reducer = combineReducers({ keplerGl: keplerGlReducer });
const store = createStore(reducer, {}, applyMiddleware(taskMiddleware));
```

### Loading data — `addDataToMap`
```javascript
import { addDataToMap } from '@kepler.gl/actions';
import { processCsvData, processGeojson } from '@kepler.gl/processors';

store.dispatch(addDataToMap({
  datasets: {
    info: { label: 'Trips', id: 'trips' },
    data: processCsvData(csvString)   // or processGeojson(geojson) or {fields, rows}
  },
  option: { centerMap: true, readOnly: false },
  config: keplerConfig   // optional saved config (layers/filters/mapState)
}));
```
Raw dataset shape (if not using a processor):
```javascript
data: {
  fields: [ {name:'lat', type:'real'}, {name:'lng', type:'real'}, {name:'value', type:'integer'} ],
  rows:   [ [37.77, -122.41, 100], [40.71, -74.00, 200] ]
}
```

### Config object (reproducible view)
The config encodes `visState` (layers, filters, interaction), `mapState` (camera), and `mapStyle` (theme).
```javascript
const keplerConfig = {
  version: 'v1',
  config: {
    visState: {
      layers: [{
        type: 'point',           // point | arc | line | grid | hexagon | geojson | heatmap | cluster | icon | trip | h3
        config: {
          dataId: 'trips',
          columns: { lat: 'lat', lng: 'lng' },
          isVisible: true,
          visConfig: { radius: 10, opacity: 0.8, colorRange: { colors: ['#ff0000','#00ff00'] } },
          colorField: { name: 'value', type: 'integer' },
          colorScale: 'quantize'
        }
      }],
      filters: [{ dataId: ['trips'], name: 'value', type: 'range', value: [0, 500] }]
    },
    mapState: { latitude: 37.77, longitude: -122.41, zoom: 11, pitch: 0, bearing: 0 },
    mapStyle: { styleType: 'dark' }
  }
};
```

### Python config round-trip
```python
config = m.config          # grab the current UI state (dict)
m2 = KeplerGl(height=600, data={'trips': df}, config=config)  # reproduce it
```

## Supported Layer Types
`point`, `icon`, `arc`, `line`, `grid`, `hexbin`, `h3`, `geojson` (polygons/lines), `cluster`, `heatmap`, `trip` (animated), `3D building`. Filters: range, time-range (animation), select, multi-select, polygon. All rendered by deck.gl on the GPU.

## How-To (worked recipes)

### How to set colors / style a layer (colorField + colorRange)
Kepler colors a layer by mapping a **`colorField`** through a **`colorScale`** onto a **`colorRange`** palette. In the UI: layer → Color → pick field + palette. In config:
```javascript
layers: [{
  type: 'hexagon',
  config: {
    dataId: 'trips',
    columns: { lat: 'lat', lng: 'lng' },
    colorField: { name: 'value', type: 'integer' },
    colorScale: 'quantile',    // quantize | quantile | ordinal | jenks
    visConfig: {
      colorRange: { name: 'Custom', type: 'sequential', category: 'Uber',
                    colors: ['#FFFFCC','#FD8D3C','#E31A1C','#800026'] },
      opacity: 0.8, coverage: 0.9, elevationScale: 5
    },
    heightField: { name: 'value', type: 'integer' }   // 3D extrusion by value
  }
}]
```

### How to build and export a map from Python
```python
from keplergl import KeplerGl
import pandas as pd
df = pd.read_csv('trips.csv')
m = KeplerGl(height=700, data={'trips': df})
m.save_to_html(file_name='trips_map.html', read_only=True)   # shareable standalone file
```

### How to animate time-series data (trip layer + time filter)
Include a timestamp column; add a `trip` layer (needs a GeoJSON LineString with a 4th coordinate = epoch) or a time-range filter on a point layer:
```javascript
filters: [{ dataId: ['trips'], name: 'timestamp', type: 'timeRange',
            value: [startEpochMs, endEpochMs], enlarged: true, animationWindow: 'incremental' }]
```

### How to switch the base map theme
```javascript
mapStyle: { styleType: 'dark' }   // 'dark' | 'light' | 'muted' | 'satellite' | custom style id
```
Python: set it in `config['config']['mapStyle']` and re-instantiate.

## Do's and Don'ts

### ✅ Do
- Use the **config object** to make an agent-generated view reproducible.
- Preprocess with `processCsvData` / `processGeojson` (JS) — they infer field types Kepler needs.
- Provide a Mapbox token *or* choose a MapLibre/no-token base style; the map is gray without a valid base.
- Use hexbin/grid/heatmap layers for millions of rows instead of raw points.
- In Python, grab `m.config` after arranging the UI to capture the exact styling.

### ❌ Don't
- Don't forget the `taskMiddleware` (react-palm) in the Redux store — actions silently fail without it.
- Don't hand-build `{fields, rows}` with wrong `type`s — color/size fields won't be selectable.
- Don't ship huge CSV strings when a saved config + hosted data URL would do.
- Don't expect fine-grained pixel control — Kepler trades precision for a fast no-code UI; drop to deck.gl for that.
- Don't mix incompatible `@kepler.gl/*` and `kepler.gl` package versions (the scoped packages are current).

## Styling, Theming & Customization
- **Layer color**: `colorField` + `colorScale` + `colorRange` (built-in ColorBrewer/Uber palettes or custom `colors` array).
- **Size/height**: `sizeField`/`heightField` + scale for graduated symbols and 3D extrusion.
- **Base map theme**: `mapStyle.styleType` (`dark`/`light`/`muted`/`satellite`) or a custom Mapbox style.
- **Opacity, radius, coverage, stroke** live in each layer's `visConfig`.
- **Filters** double as visual scoping tools (range/time/polygon).

## Advanced Features
- Time-range animation with playback controls.
- Polygon filter to spatially subset any dataset.
- 3D pitch/bearing, hexbin/grid elevation, arc origin-destination flows.
- H3 hexagon layer for spatial-index data.
- Data joins across datasets; brushing/linked interaction.
- Export to HTML, PNG, or JSON config; embeddable read-only maps.

## Common Pitfalls & Troubleshooting
- **Gray/blank base map**: missing/invalid token and no MapLibre fallback style.
- **Redux actions do nothing**: `taskMiddleware` not applied.
- **Fields not offered for color/size**: dataset `type`s wrong, or column not numeric/timestamp.
- **Slow with big data**: use aggregation layers, sample, or host data instead of inlining.
- **Config won't reproduce**: version mismatch between the config `version` and the kepler.gl release.

## Best For / Avoid For
`no-code-geo`, `big-data-exploration`, `time-animation`, `hexbin`, `origin-destination`, `dashboards` — Best for interactive exploration of large geo datasets without writing rendering code.
Avoid for: bespoke pixel-perfect visuals (deck.gl), lightweight single-pin maps (Leaflet), pure server-side analysis (GeoPandas).

## See Also
- [deck_gl.md](deck_gl.md) — the rendering engine underneath; use it for custom control
- [mapbox-gl-js.md](mapbox-gl-js.md), [maplibre-gl-js.md](maplibre-gl-js.md) — base map layer
- [geopandas.md](geopandas.md), [folium.md](folium.md) — Python geo prep / lightweight maps
- `../use-case/geospatial-mapping.md`
