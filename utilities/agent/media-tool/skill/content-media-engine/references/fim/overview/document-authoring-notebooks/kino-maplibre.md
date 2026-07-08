# Kino.MapLibre

## What
Kino.MapLibre provides interactive MapLibre GL JS maps for Elixir LiveBook — embedding vector-based maps with custom styling, data layers, and interactive controls directly in notebook cells.

## How
- The LLM emits Elixir: `MapLibre.new(center: {lng, lat}, zoom: n)` piped through `MapLibre.add_source(...)` (e.g. GeoJSON) and `MapLibre.add_layer(...)` with paint properties.
- Rendered by evaluating the LiveBook cell after `Mix.install([{:kino_maplibre, "~> 0.1.10"}, {:kino, "~> 0.12.0"}])`.
- Final artifact: an interactive vector map (pan/zoom/rotate/tilt) rendered in a LiveBook cell.

## Why
- Reach for Kino.MapLibre for geographic/spatial analysis, location intelligence, data-journalism map stories, and map prototyping within Elixir LiveBook, with GeoJSON/vector-tile/raster data layers and full styling control.
- Tradeoffs: LiveBook-only, needs internet access to a tile server for base maps, complex geometries can slow rendering, and advanced styling requires MapLibre knowledge.
- It is the geospatial member of the Kino family, bringing MapLibre GL into notebooks the way Kino.Plotly brings Plotly.

## Source
- Solution reference: `fim/solution/kino-maplibre.md`
