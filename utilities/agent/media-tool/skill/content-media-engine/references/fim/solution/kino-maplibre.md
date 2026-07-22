# Kino.MapLibre — Interactive vector maps in Elixir Livebook

Kino.MapLibre renders [MapLibre GL JS](https://maplibre.org/) vector maps inside Livebook. You compose a map declaratively with the pure-Elixir `MapLibre` DSL (`MapLibre.new/1` + `add_source`/`add_layer`/…), which produces a MapLibre **style spec**, then either return that spec (static, renders once) or wrap it in `Kino.MapLibre.new/1` for a **dynamic** map you can mutate at runtime (add markers, fly to coordinates, update GeoJSON). Runs only inside Livebook/Kino; needs network access to a tile/style server.

**Current Version**: `kino_maplibre ~> 0.1.10`, `maplibre ~> 0.1.x` (current)  **License**: Apache-2.0 (Kino), BSD-3 (MapLibre GL JS)  **Runtime**: Livebook / Kino; MapLibre GL JS in-browser

## Official Resources & Documentation
- Kino.MapLibre docs: https://hexdocs.pm/kino_maplibre
- `maplibre` (the DSL) docs: https://hexdocs.pm/maplibre
- MapLibre GL JS docs: https://maplibre.org/maplibre-gl-js/docs/
- MapLibre style spec: https://maplibre.org/maplibre-style-spec/
- Repo: https://github.com/livebook-dev/kino_maplibre
- Free demo styles/tiles: https://demotiles.maplibre.org/style.json

## Installation & Setup
### Mix / Livebook setup cell
```elixir
Mix.install([
  {:kino_maplibre, "~> 0.1.10"},
  {:kino, "~> 0.12"}
])
```
`kino_maplibre` pulls in `maplibre`. Alias for readability:
```elixir
alias MapLibre, as: Ml
```

### Styles & tiles
A map needs a base style. `MapLibre.new/1` defaults to a demo style; for real basemaps pass `style:` a MapLibre style URL/JSON (MapTiler, Stadia, Protomaps, or a self-hosted style). Many providers require an API key in the style URL.

### Smart cell (no code)
Livebook ships a **"Map"** smart cell backed by Kino.MapLibre: pick center/zoom, add GeoJSON/coordinate layers from bound variables, and it emits the `MapLibre` pipeline.

## Core Syntax / API Reference

### Two layers: `MapLibre` DSL (static) vs `Kino.MapLibre` (dynamic)
- `MapLibre.*` builds an immutable style spec you keep piping.
- `Kino.MapLibre.new/1` wraps it in a live widget whose `Kino.MapLibre.*` functions mutate the rendered map.

### `MapLibre.new/1` options
```elixir
Ml.new(
  center: {-74.5, 40.0},   # {lng, lat} — note lng first
  zoom: 9,                  # 0 (world) … 22 (building)
  style: :street,           # atom preset, or a style URL/JSON map
  bearing: 0,               # rotation in degrees
  pitch: 0                  # tilt 0–60
)
```
Coordinates are `{longitude, latitude}` throughout MapLibre — longitude first. This trips up almost everyone once.

### Sources — where data comes from
```elixir
Ml.add_source(map, "quakes",
  type: :geojson,
  data: "https://maplibre.org/maplibre-gl-js/docs/assets/earthquakes.geojson")

Ml.add_source(map, "pts", type: :geojson, data: geojson_map)  # inline GeoJSON map
```
Source `type:` values: `:geojson`, `:vector`, `:raster`, `:raster_dem`, `:image`.

### Layers — how data is drawn
```elixir
Ml.add_layer(map,
  id: "quake-points",
  source: "quakes",
  type: :circle,
  paint: %{
    "circle-radius" => 6,
    "circle-color" => "#e11d48",
    "circle-opacity" => 0.8,
    "circle-stroke-width" => 1,
    "circle-stroke-color" => "#fff"
  }
)
```
Layer `type:` values: `:circle`, `:fill`, `:line`, `:symbol` (icons/labels), `:heatmap`, `:fill_extrusion` (3D), `:raster`, `:background`. Styling lives in `paint:` (color/size/opacity, per type) and `layout:` (visibility, symbol placement, text fields).

### Convenience builders (`maplibre` DSL)
```elixir
Ml.add_geocode_source(map, "coords", "New York")           # geocode a place name
Ml.add_table_source(map, "cities", table, {:lng_lat, "coordinates"})  # from tabular data
```

### `Kino.MapLibre` dynamic functions
Wrap the spec, then mutate:
```elixir
kmap = Kino.MapLibre.new(map)
Kino.MapLibre.add_marker(kmap, {-74.5, 40.0}, color: "#2563eb", draggable: true)
Kino.MapLibre.add_nav_controls(kmap, show_compass: true)
Kino.MapLibre.update_geojson(kmap, "pts", new_geojson)   # swap a source's data live
Kino.MapLibre.add_hover(kmap, "quake-points")             # hover highlight
Kino.MapLibre.add_custom_image(kmap, "pin", image_url)
```
`Kino.MapLibre.*` mutators only work on a widget from `Kino.MapLibre.new/1`, not on a bare `%MapLibre{}`.

## Map/layer types you can produce
Point maps (`:circle` or `:symbol`), choropleths and filled polygons (`:fill`), routes/boundaries (`:line`), labeled icon maps (`:symbol`), density/heatmaps (`:heatmap`), 3D extruded buildings/prisms (`:fill_extrusion`), raster overlays (`:raster`), and combinations layered over any vector or raster basemap.

## How-To (worked recipes)

### How to add colors / data-driven styling to a map
Static color is a string; data-driven color uses a MapLibre **expression** (a nested list) reading a feature property:
```elixir
Ml.new(center: {-98, 39}, zoom: 3)
|> Ml.add_source("states", type: :geojson, data: states_geojson)
|> Ml.add_layer(
  id: "choropleth",
  source: "states",
  type: :fill,
  paint: %{
    "fill-color" => [
      "interpolate", ["linear"], ["get", "density"],
      0, "#f1f5f9",
      50, "#60a5fa",
      200, "#1e3a8a"
    ],
    "fill-opacity" => 0.75,
    "fill-outline-color" => "#334155"
  }
)
```
Categorical color uses `["match", ["get", "type"], "a", "#f00", "b", "#0f0", "#999"]`. This expression syntax is the MapLibre style-spec, expressed as Elixir lists.

### How to plot GeoJSON points with a circle layer
```elixir
geojson = %{
  type: "FeatureCollection",
  features: [
    %{type: "Feature",
      geometry: %{type: "Point", coordinates: [-74.006, 40.7128]},
      properties: %{name: "NYC"}}
  ]
}

Ml.new(center: {-74.006, 40.7128}, zoom: 10)
|> Ml.add_source("cities", type: :geojson, data: geojson)
|> Ml.add_layer(id: "city-dots", source: "cities", type: :circle,
     paint: %{"circle-radius" => 8, "circle-color" => "#007cbf"})
```

### How to add markers and navigation controls (dynamic map)
```elixir
kmap =
  Ml.new(center: {-0.09, 51.505}, zoom: 12)
  |> Kino.MapLibre.new()

Kino.MapLibre.add_marker(kmap, {-0.09, 51.505}, color: "#dc2626")
Kino.MapLibre.add_nav_controls(kmap, show_zoom: true, show_compass: true)
kmap
```

### How to make a heatmap
```elixir
Ml.new(center: {-120, 37}, zoom: 4)
|> Ml.add_source("q", type: :geojson, data: quakes_url)
|> Ml.add_layer(id: "heat", source: "q", type: :heatmap,
     paint: %{
       "heatmap-weight" => ["interpolate", ["linear"], ["get", "mag"], 0, 0, 6, 1],
       "heatmap-radius" => 20,
       "heatmap-opacity" => 0.85
     })
```

### How to stream/update map data at runtime
```elixir
kmap = Ml.new(center: {0, 0}, zoom: 2)
       |> Ml.add_source("live", type: :geojson, data: empty_fc())
       |> Ml.add_layer(id: "live-pts", source: "live", type: :circle)
       |> Kino.MapLibre.new()

# later, as new data arrives:
Kino.MapLibre.update_geojson(kmap, "live", latest_feature_collection)
```

## Do's and Don'ts
### ✅ Do
- Remember coordinates are `{longitude, latitude}` — lng first, everywhere.
- Use `Kino.MapLibre.new/1` only when you need runtime mutation; otherwise return the `%MapLibre{}` spec directly.
- Drive color/size from data with `["interpolate", …]` / `["match", …]` expressions instead of pre-coloring features.
- Add a source before the layer that references it.
- Use `add_geocode_source`/`add_table_source` to skip hand-writing GeoJSON.

### ❌ Don't
- Don't swap lat/lng — your points will land in the ocean off Africa (the `{0,0}` symptom is usually a real swap elsewhere).
- Don't call `Kino.MapLibre.add_marker/update_geojson` on a static `%MapLibre{}` — wrap it first.
- Don't reference a `source:` id in a layer that you never added.
- Don't inline huge GeoJSON (MBs) — host it and pass a URL; the browser fetches it directly.
- Don't forget a valid `style:`/tiles provider — a keyless commercial style renders blank.

## Styling, Theming & Customization
- **Basemap style**: `style:` accepts atom presets (e.g. `:street`, `:terrain` where provided), a style-JSON URL, or an inline style map. Swap the whole look by swapping the style.
- **Paint properties** (per layer type): `circle-color`/`circle-radius`, `fill-color`/`fill-opacity`, `line-color`/`line-width`/`line-dasharray`, `heatmap-*`, `fill-extrusion-height`/`-color`.
- **Data-driven expressions**: `["get", prop]`, `["interpolate", …]`, `["match", …]`, `["step", …]` — the core of thematic maps.
- **Symbol layers**: `layout: %{"text-field" => ["get","name"], "icon-image" => "pin"}` for labels/icons.
- **Controls**: nav (zoom/compass), scale, and geolocate via `Kino.MapLibre.add_*_controls`.

## Advanced Features
- **3D**: `:fill_extrusion` layers with `fill-extrusion-height` (data-driven) plus map `pitch:` for extruded polygons/buildings.
- **Clustering**: enable on a GeoJSON source (`cluster: true`, `cluster_radius:`), then style cluster/leaf layers separately.
- **Interactivity**: `add_hover`, draggable markers, and popups; pan/zoom/rotate/tilt are built in.
- **Vector tiles**: point a `:vector` source at an MVT endpoint and style specific `source-layer`s.
- **Export**: the map is live JS; capture via screenshot. The style spec is portable to any MapLibre/Mapbox-GL runtime.

## Common Pitfalls & Troubleshooting
- **Blank map**: missing/keyless `style:` provider, or no network access to tiles.
- **Points in the wrong place**: lng/lat swapped, or coordinates as strings instead of numbers.
- **Layer draws nothing**: `source:` id typo, or the source added after the layer.
- **Data-driven color flat**: the property name in `["get","x"]` doesn't exist on the features, or values fall outside the interpolate stops.
- **Dynamic call ignored**: you mutated a `%MapLibre{}` spec instead of a `Kino.MapLibre` widget.
- **Slow/janky**: oversized inline GeoJSON — host it and pass a URL, or cluster.

## Integration Notes (Livebook/Kino)
- The "Map" smart cell turns a bound table/DataFrame of coordinates into a map without writing the pipeline.
- Pairs with Explorer (shape lat/lng tables) and `Kino.DataTable` (inspect features) in one notebook.
- The emitted style spec is standard MapLibre/Mapbox-GL JSON — reusable outside Livebook with maplibre-gl in a web page.

## Best For / Avoid For
`livebook`, `elixir`, `maps`, `geospatial`, `geojson`, `vector-tiles`, `choropleth`, `data-journalism`
- **Best for**: interactive spatial exploration in Elixir, choropleths/heatmaps/point maps from GeoJSON or tabular coordinates, location analysis, map-based notebook stories.
- **Avoid for**: heavy offline/print cartography, extremely large feature sets without clustering, or non-Livebook production UIs (use maplibre-gl directly with the exported style).

## See Also
- [maplibre-gl-js.md](maplibre-gl-js.md) — MapLibre GL JS in a plain web page
- [leaflet_js.md](leaflet_js.md) — simpler raster-tile mapping alternative
- [kino-datatable.md](kino-datatable.md) — inspect the feature attributes
- [kino-js.md](kino-js.md) — custom widget escape hatch
- `../use-case/geospatial-mapping.md`, `../use-case/elixir-livebook-components.md`
