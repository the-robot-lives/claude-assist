# GeoPandas — Geospatial vector data analysis in Python

GeoPandas extends pandas with a `geometry` column of Shapely objects, giving you a `GeoDataFrame`/`GeoSeries` that behaves like a DataFrame but supports spatial operations: read/write dozens of formats (Shapefile, GeoJSON, GeoPackage, PostGIS), reproject between coordinate reference systems, run geometric ops (buffer, intersection, union), spatial joins, and static/interactive plotting. It sits on Shapely (geometry), pyogrio/Fiona (I/O), and pyproj (CRS). It is the backbone of Python GIS analysis and the usual data-prep step before Folium/matplotlib visualization.

**Current Version**: 1.0.x (current major; 0.14 legacy)  **License**: BSD-3-Clause  **Python**: 3.9+

## Official Resources & Documentation
- **Docs**: https://geopandas.org/
- **API reference**: https://geopandas.org/en/stable/docs.html
- **User guide**: https://geopandas.org/en/stable/docs/user_guide.html
- **GitHub**: https://github.com/geopandas/geopandas
- **PyPI**: https://pypi.org/project/geopandas/

## Installation & Setup
GeoPandas depends on system geospatial libs (GDAL, GEOS, PROJ). Conda bundles them; pip installs are easier since 1.0 (wheels ship binaries).
```bash
# Recommended (handles binary deps)
conda install -c conda-forge geopandas
# or pip (1.0+ wheels include GDAL/GEOS/PROJ)
pip install geopandas
# Full stack
conda install -c conda-forge geopandas matplotlib folium contextily mapclassify pyogrio
```
```python
import geopandas as gpd
gdf = gpd.read_file('data.geojson')
print(gdf.crs, gdf.geometry.geom_type.unique())
```
Note: `gpd.datasets` (naturalearth) was **removed in 1.0** — download data explicitly or use `geodatasets`.

## Core API Reference

### GeoDataFrame / GeoSeries
A `GeoDataFrame` is a pandas DataFrame with an active `geometry` column (a `GeoSeries` of Shapely geometries) plus a `.crs`.
```python
from shapely.geometry import Point
import pandas as pd
df = pd.DataFrame({'city': ['NYC','LA'], 'lat': [40.71, 34.05], 'lon': [-74.0, -118.2]})
gdf = gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(df.lon, df.lat), crs='EPSG:4326')
```

### Reading & writing
```python
gdf = gpd.read_file('data.shp')            # shp, geojson, gpkg, kml, ...
gdf = gpd.read_file('data.gpkg', layer='roads', bbox=(minx, miny, maxx, maxy))
gdf = gpd.read_postgis('SELECT * FROM t', engine, geom_col='geom')

gdf.to_file('out.geojson', driver='GeoJSON')
gdf.to_file('out.gpkg', layer='cities', driver='GPKG')
gdf.to_parquet('out.parquet')              # GeoParquet — fast, preserves CRS
```

### CRS (coordinate reference systems)
```python
gdf.crs                       # inspect
gdf = gdf.set_crs('EPSG:4326')          # assign when missing (does NOT move points)
gdf = gdf.to_crs('EPSG:3857')           # reproject (moves coordinates)
utm = gdf.estimate_utm_crs()            # best local UTM for accurate metric ops
gdf_m = gdf.to_crs(utm)
```
EPSG:4326 = lon/lat degrees (geographic). EPSG:3857 = Web Mercator metres. UTM zones = accurate local metres for area/length.

### Geometric operations (vectorized on GeoSeries)
```python
gdf['area']     = gdf.to_crs(utm).geometry.area          # project first!
gdf['length']   = gdf.to_crs(utm).geometry.length
gdf['centroid'] = gdf.geometry.centroid
gdf['buffered'] = gdf.to_crs(utm).geometry.buffer(1000)  # metres
gdf['hull']     = gdf.geometry.convex_hull
gdf['simple']   = gdf.geometry.simplify(0.01, preserve_topology=True)
gdf.geometry = gdf.geometry.make_valid()                 # fix self-intersections
```
Predicates: `.intersects()`, `.contains()`, `.within()`, `.touches()`, `.distance(other)`.

### Overlay & dissolve
```python
gpd.overlay(a, b, how='intersection')   # or 'union','difference','symmetric_difference','identity'
gdf.dissolve(by='state', aggfunc='sum') # merge geometries by attribute
```

### Spatial joins
```python
gpd.sjoin(points, polygons, how='inner', predicate='within')   # tag points with polygon attrs
gpd.sjoin_nearest(points, lines, distance_col='dist')          # nearest feature + distance
```

### Plotting
```python
import matplotlib.pyplot as plt
ax = gdf.plot(column='pop', cmap='OrRd', legend=True, scheme='quantiles', k=5,
              edgecolor='black', linewidth=0.3, figsize=(10, 8))
ax.set_axis_off()
gdf.explore(column='pop', cmap='OrRd')     # interactive Folium map
```

## Supported Formats / Types
Geometry types: Point, LineString, Polygon, and Multi* + GeometryCollection. I/O: Shapefile, GeoJSON, GeoPackage, KML, GML, GPX, FlatGeobuf, PostGIS, GeoParquet, plus anything GDAL/pyogrio supports. Static plots via matplotlib; interactive via `.explore()` (Folium).

## How-To (worked recipes)

### How to set colors / style a plot (choropleth + classification)
`plot()` maps a `column` to a matplotlib `cmap`; a `scheme` (from mapclassify) bins values into classes.
```python
ax = gdf.plot(
    column='income',
    cmap='viridis',            # any matplotlib colormap
    scheme='NaturalBreaks',    # requires mapclassify; also 'Quantiles','EqualInterval'
    k=6,
    legend=True,
    legend_kwds={'title': 'Median income', 'loc': 'lower left'},
    edgecolor='white', linewidth=0.4,
    missing_kwds={'color': 'lightgrey', 'label': 'No data'}
)
ax.set_axis_off()
```
Solid single color: `gdf.plot(color='#1f77b4', edgecolor='black')`. Layer multiple GeoDataFrames by passing the same `ax`.

### How to reproject for accurate area/distance
```python
utm = gdf.estimate_utm_crs()
gdf_m = gdf.to_crs(utm)
gdf['area_km2'] = gdf_m.geometry.area / 1e6      # NEVER compute area in EPSG:4326 degrees
```

### How to spatially join points into regions and count them
```python
joined = gpd.sjoin(points, regions[['region', 'geometry']], predicate='within')
counts = joined.groupby('region').size().rename('n')
regions = regions.merge(counts, on='region', how='left').fillna({'n': 0})
```

### How to add a basemap tile behind vector data
```python
import contextily as ctx
gdf_web = gdf.to_crs('EPSG:3857')
ax = gdf_web.plot(alpha=0.7, edgecolor='k', figsize=(10, 10))
ctx.add_basemap(ax, source=ctx.providers.CartoDB.Positron)
ax.set_axis_off()
```

### How to clip data to a boundary
```python
clipped = gpd.clip(gdf, boundary_gdf)        # keep only geometry inside boundary
# or mask a raster of vectors with a bounding box:
subset = gdf.cx[minx:maxx, miny:maxy]        # coordinate-based slice
```

### How to save an interactive choropleth to HTML
```python
m = gdf.to_crs('EPSG:4326').explore(
    column='pop', cmap='OrRd', scheme='quantiles', k=5,
    tiles='CartoDB positron', legend=True, tooltip=['name', 'pop'])
m.save('choropleth.html')      # Folium map under the hood
```

## Do's and Don'ts

### ✅ Do
- **Reproject to a metric CRS (UTM/equal-area) before `.area`/`.length`/`.buffer`** — degrees are not metres.
- Ensure both operands share a CRS before overlay/sjoin (`b.to_crs(a.crs)`).
- Use `pyogrio` engine (default in 1.0) for fast I/O; use GeoParquet for large intermediate data.
- Call `.make_valid()` (or `.buffer(0)`) on invalid geometries before overlays.
- Use `estimate_utm_crs()` instead of hard-coding a zone.

### ❌ Don't
- Don't compute area/length in EPSG:4326 — results are meaningless (square degrees).
- Don't confuse `set_crs` (label only) with `to_crs` (actually reproject) — swapping them corrupts coordinates.
- Don't rely on `gpd.datasets.get_path(...)` — removed in 1.0.
- Don't overlay/join layers with mismatched CRS — you get wrong or empty results, sometimes silently.
- Don't loop Python-side over geometries for ops that have vectorized GeoSeries methods (slow).

## Styling, Theming & Customization
- **Choropleth**: `column` + `cmap` + `scheme`/`k` + `legend`.
- **Classification schemes** (mapclassify): `Quantiles`, `EqualInterval`, `NaturalBreaks`, `FisherJenks`, `StdMean`, `UserDefined` (`classification_kwds={'bins': [...]}`).
- **Missing data**: `missing_kwds`.
- **Categorical**: `categorical=True` colors by discrete values.
- **Interactive theming**: `.explore(cmap=..., tiles='CartoDB dark_matter', style_kwds={...})`.
- **Layered maps**: pass a shared `ax`; control z-order by plot order.

## Advanced Features
- Spatial index (`.sindex`) auto-used by sjoin/overlay for speed.
- Dask-GeoPandas for out-of-core / parallel worklods.
- Raster integration via rasterio (`mask`, `rasterize`, point sampling).
- PostGIS round-trip (`read_postgis`/`to_postgis`).
- `sjoin_nearest`, `clip`, `dissolve`, `explode` (multipart → single), `sample_points`.

## Common Pitfalls & Troubleshooting
- **Area/length nonsense**: computed in a geographic CRS — reproject first.
- **`CRSError`/empty join**: CRS mismatch between layers.
- **`TopologyException`/`GEOSException`** in overlay: invalid geometry — `make_valid()`.
- **Slow read of big files**: use `pyogrio`, `bbox=`/`rows=` filtering, or GeoParquet.
- **Install failures (pip, older versions)**: missing GDAL/GEOS/PROJ — use conda-forge or GeoPandas ≥1.0 wheels.

## Integration Notes
- **Folium**: `folium.GeoJson(gdf.to_crs('EPSG:4326'))` or `gdf.explore()`.
- **matplotlib/contextily**: static maps with basemaps.
- **Shapely**: element-wise geometry access via `gdf.geometry.iloc[i]`.
- **Jupyter**: `.explore()` returns an inline interactive map.

## Best For / Avoid For
`geospatial-analysis`, `crs-reprojection`, `spatial-join`, `choropleth-prep`, `gis-workflows`, `postgis` — Best for analyzing and transforming vector geodata in Python before visualization.
Avoid for: raster analysis (use rasterio/xarray), interactive web maps as the end product (feed Folium/deck.gl/kepler), billions of rows (Dask-GeoPandas or a spatial DB).

## See Also
- [folium.md](folium.md) — turn a GeoDataFrame into an interactive map
- [leaflet_js.md](leaflet_js.md), [openlayers.md](openlayers.md) — JS renderers for exported GeoJSON
- [kepler_gl.md](kepler_gl.md) — Python bridge accepts GeoDataFrames
- [turf_js.md](turf_js.md) — the JS analog for client-side analysis
- `../use-case/geospatial-mapping.md`, `../solution/matplotlib.md`
