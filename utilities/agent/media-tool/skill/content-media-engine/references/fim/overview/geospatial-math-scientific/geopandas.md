# GeoPandas

## What
GeoPandas is a Python library that extends pandas with spatial data types and operations, giving you pandas-style DataFrames (`GeoDataFrame`) for vector geographic data. It is a Python-runtime analysis library, built on Shapely, Fiona, and PyProj, with matplotlib-based plotting for static map output.

## How
- The LLM emits **Python/GeoPandas code** — `gpd.read_file(...)`, geometric operations (buffer, intersection, union), CRS transforms (`.to_crs(...)`), and `.plot(...)`.
- That code runs in a Python environment: read spatial data from Shapefile/GeoJSON/GeoPackage/PostGIS, manipulate it like a DataFrame, then render with the built-in matplotlib `.plot()` or hand geometries to a mapping library.
- Requires system-level geospatial libraries (**GDAL, GEOS, PROJ**) installed first (via apt/brew/conda).
- Typical final artifact: a **static matplotlib figure (PNG/SVG/PDF)** or a transformed spatial dataset for downstream use.

## Why
- Reach for GeoPandas when the task is spatial **analysis** — census data, administrative boundaries, proximity/catchment studies, service-area planning — where familiar DataFrame semantics plus R-tree spatial indexing matter more than interactivity.
- Limitations: high memory use and slow operations on very large datasets, complex system-dependency installation (especially on Windows without conda), primarily vector-focused (use rasterio for raster), and limited multi-core utilization.
- Relative to its siblings: GeoPandas is the analysis layer, not a map renderer — pair it with `folium` (interactive) or its own matplotlib plots (static) for display; `turf_js` is the closest JavaScript-side analog for geometric operations.

## Source
- Solution reference: `fim/solution/geopandas.md`
