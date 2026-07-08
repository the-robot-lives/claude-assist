# Folium — Interactive Leaflet maps from Python

Folium builds interactive Leaflet.js maps from Python and serializes them to a standalone HTML file (or renders inline in Jupyter). You compose a `folium.Map` with markers, vector shapes, GeoJSON/Choropleth layers, tile layers, and plugins — no JavaScript required — then `.save('map.html')` or return it as the last cell value. It is the standard "quick interactive map" tool in the Python data-science stack and integrates tightly with pandas and GeoPandas.

**Current Version**: 0.17.x (current)  **License**: MIT  **Python**: 3.8+  **Output**: self-contained HTML (Leaflet under the hood)

## Official Resources & Documentation
- **Docs**: https://python-visualization.github.io/folium/
- **API reference**: https://python-visualization.github.io/folium/latest/reference.html
- **Plugins**: https://python-visualization.github.io/folium/latest/user_guide/plugins.html
- **GitHub**: https://github.com/python-visualization/folium
- **PyPI**: https://pypi.org/project/folium/

## Installation & Setup
```bash
pip install folium
# with optional deps (geopandas, matplotlib colormaps, selenium PNG export)
pip install "folium[all]"
# conda
conda install -c conda-forge folium
```
```python
import folium
m = folium.Map(location=[45.5236, -122.6750], zoom_start=12, tiles='OpenStreetMap')
m.save('map.html')      # write standalone HTML
m                        # in Jupyter, returns the last expression to render inline
```

## Core API Reference

### Map — `folium.Map(...)`
```python
m = folium.Map(
    location=[lat, lon],       # [lat, lon] — lat FIRST
    zoom_start=10,
    tiles='CartoDB positron',  # built-in theme or a custom URL template
    attr=None,                 # required attribution string when tiles is a URL
    control_scale=True,
    prefer_canvas=True,        # canvas rendering — faster for many vectors
    crs='EPSG3857'
)
```
Built-in `tiles`: `'OpenStreetMap'`, `'CartoDB positron'`, `'CartoDB dark_matter'`, `'CartoDB voyager'`. Others need an explicit URL + `attr`.

### Markers & icons
```python
folium.Marker(
    location=[lat, lon],
    popup=folium.Popup('<b>Name</b>', max_width=250),
    tooltip='Hover text',
    icon=folium.Icon(color='red', icon='cutlery', prefix='fa')  # prefix='fa' for Font Awesome
).add_to(m)

folium.CircleMarker([lat, lon], radius=8, color='#c00', fill=True,
                    fill_color='#f66', fill_opacity=0.6).add_to(m)   # radius in PIXELS
folium.Circle([lat, lon], radius=500, color='#08c').add_to(m)        # radius in METERS
```

### Vector shapes
```python
folium.PolyLine([[la,lo],[la2,lo2]], color='#06f', weight=4).add_to(m)
folium.Polygon([[la,lo],...], color='#093', fill=True, fill_opacity=0.4).add_to(m)
folium.Rectangle([[s,w],[n,e]]).add_to(m)
```

### GeoJSON & Choropleth
```python
folium.GeoJson(
    geojson_data,
    style_function=lambda feat: {'fillColor': '#3388ff', 'color': '#000', 'weight': 1, 'fillOpacity': 0.5},
    highlight_function=lambda feat: {'weight': 3, 'color': '#f00'},
    tooltip=folium.GeoJsonTooltip(fields=['name', 'value'], aliases=['Region:', 'Value:'])
).add_to(m)

folium.Choropleth(
    geo_data=geojson_or_path,
    data=dataframe,
    columns=['region_id', 'value'],
    key_on='feature.properties.region_id',
    fill_color='YlOrRd',        # ColorBrewer scheme
    fill_opacity=0.7, line_opacity=0.2,
    bins=9, legend_name='Value by region'
).add_to(m)
```

### Tile layers & layer control
```python
folium.TileLayer('CartoDB dark_matter', name='Dark').add_to(m)
folium.TileLayer(
    tiles='https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attr='Esri', name='Satellite'
).add_to(m)
folium.LayerControl().add_to(m)    # add LAST, after all toggleable layers
```

### FeatureGroup (grouped, toggleable)
```python
fg = folium.FeatureGroup(name='Stores').add_to(m)
for s in stores:
    folium.Marker([s['lat'], s['lon']], popup=s['name']).add_to(fg)
```

### Plugins (`from folium.plugins import ...`)
`HeatMap`, `MarkerCluster`, `FastMarkerCluster`, `Fullscreen`, `MiniMap`, `MeasureControl`, `Draw`, `TimestampedGeoJson`, `Geocoder`, `HeatMapWithTime`, `DualMap`, `AntPath`, `LocateControl`.

## Supported Layer/Output Types
Markers, CircleMarker, Circle, PolyLine, Polygon, Rectangle, GeoJson, TopoJson, Choropleth, raster TileLayer, ImageOverlay, plus plugin layers (heatmap, clusters, time animation, draw). Output is always a static HTML/Leaflet artifact.

## How-To (worked recipes)

### How to set colors / style a layer
Vector shapes take Leaflet path options directly as kwargs (`color`, `weight`, `fill_color`, `fill_opacity`). GeoJSON uses a **`style_function`** returning a dict of Leaflet paint keys:
```python
def ramp(v):
    return '#800026' if v > 100 else '#e31a1c' if v > 50 else '#fd8d3c' if v > 10 else '#ffeda0'

folium.GeoJson(data, style_function=lambda f: {
    'fillColor': ramp(f['properties']['value']),
    'color': 'white', 'weight': 1, 'fillOpacity': 0.7
}).add_to(m)
```
For statistical maps prefer `Choropleth` with a ColorBrewer `fill_color` (`'YlOrRd'`, `'BuPu'`, `'Greens'`, ...) and `bins`.

### How to make a choropleth from a DataFrame
```python
import folium, pandas as pd
df = pd.DataFrame({'state': ['CA','TX','FL'], 'val': [820, 640, 410]})
m = folium.Map([39, -98], zoom_start=4, tiles='CartoDB positron')
folium.Choropleth(geo_data='us_states.geojson', data=df,
    columns=['state', 'val'], key_on='feature.id',
    fill_color='PuBu', legend_name='Value').add_to(m)
m.save('choropleth.html')
```

### How to cluster many markers for performance
```python
from folium.plugins import MarkerCluster
cluster = MarkerCluster().add_to(m)
for _, row in df.iterrows():
    folium.Marker([row.lat, row.lon], popup=row['name']).add_to(cluster)
```

### How to add a heatmap
```python
from folium.plugins import HeatMap
HeatMap(df[['lat', 'lon', 'weight']].values.tolist(),
        radius=25, blur=15, gradient={0.4: 'blue', 0.65: 'lime', 1: 'red'}).add_to(m)
```

### How to add multiple base layers with a switcher
```python
folium.TileLayer('OpenStreetMap').add_to(m)
folium.TileLayer('CartoDB dark_matter', name='Dark').add_to(m)
folium.LayerControl().add_to(m)   # must be added after the layers
```

## Do's and Don'ts

### ✅ Do
- Use `[lat, lon]` order (opposite of GeoJSON's `[lon, lat]`).
- Add `folium.LayerControl()` **last**, after every toggleable layer/FeatureGroup.
- Use `prefer_canvas=True` and `MarkerCluster` for large point sets.
- Set `prefix='fa'` (Font Awesome) or `'glyphicon'` explicitly on `folium.Icon`.
- Verify `key_on` matches your GeoJSON property path exactly (e.g. `feature.properties.id`).

### ❌ Don't
- Don't expect live updates — Folium output is static; regenerate the HTML to change it.
- Don't render >~10k individual `Marker`s uncluster­ed; the browser DOM stalls.
- Don't forget `attr=` when `tiles=` is a raw URL template (raises an error otherwise).
- Don't mismatch `columns` key and `key_on` in `Choropleth` — the map renders blank/gray with no error.
- Don't swap lat/lon — points land in the wrong hemisphere.

## Styling, Theming & Customization
- **Basemap theme**: `tiles=` — `'CartoDB positron'` (light), `'CartoDB dark_matter'` (dark), Esri satellite via URL.
- **Vector color**: kwargs on shapes; `style_function` for GeoJSON.
- **Choropleth palettes**: ColorBrewer names in `fill_color` + `bins`/`threshold_scale`.
- **Custom colormaps**: `branca.colormap` (`linear.YlOrRd_09.scale(0,100)`) → use as a color function and add as a legend.
- **Custom CSS/HTML**: `m.get_root().html.add_child(folium.Element('<style>...</style>'))`.
- **Custom icons**: `folium.CustomIcon(icon_url, icon_size=(38,38))` or `folium.DivIcon(html='<div>…</div>')`.

## Advanced Features
- Time animation: `TimestampedGeoJson` / `HeatMapWithTime`.
- Side-by-side maps: `plugins.DualMap`; synced compare via `SideBySideLayers`.
- In-browser drawing/measuring: `plugins.Draw(export=True)`, `MeasureControl`.
- GeoPandas: `folium.GeoJson(gdf.to_crs('EPSG:4326'))` or `gdf.explore()` (GeoPandas' Folium-backed method).
- PNG export: `m._to_png()` (requires selenium + a headless browser).

## Common Pitfalls & Troubleshooting
- **Blank map in notebook**: trust the notebook / large HTML; try `m.save()` and open in a browser.
- **Choropleth all one color / no legend**: `key_on` doesn't match `columns[0]` join key.
- **Icons show as broken squares**: wrong/missing `prefix` on `folium.Icon`.
- **Nothing shows for a raster URL**: missing `attr`, or `{x}/{y}/{z}` template wrong (note Esri uses `{z}/{y}/{x}`).
- **Huge HTML file / slow**: too many inline markers — cluster or use `FastMarkerCluster`.

## Integration Notes
- **pandas/GeoPandas**: iterate rows for markers; `gdf.explore()` returns a Folium map directly.
- **Jupyter/Colab**: renders inline as the last expression; `IFrame`/`m._repr_html_()` for embedding.
- **Flask/Django**: serve `m._repr_html_()` or the saved file.

## Best For / Avoid For
`python-maps`, `choropleth`, `jupyter`, `eda`, `location-intelligence`, `quick-interactive-map` — Best for turning pandas/GeoPandas data into a shareable interactive Leaflet HTML with zero JS.
Avoid for: real-time/updating maps, >100k points, 3D/WebGL, fine-grained custom UI (use Leaflet/MapLibre/deck.gl directly, or kepler.gl).

## See Also
- [leaflet_js.md](leaflet_js.md) — the JS engine Folium wraps
- [geopandas.md](geopandas.md) — geospatial dataframes that feed Folium
- [kepler_gl.md](kepler_gl.md) — no-code big-geo alternative (also has a Python bridge)
- [mapbox-gl-js.md](mapbox-gl-js.md), [maplibre-gl-js.md](maplibre-gl-js.md) — JS vector alternatives
- `../use-case/geospatial-mapping.md`
