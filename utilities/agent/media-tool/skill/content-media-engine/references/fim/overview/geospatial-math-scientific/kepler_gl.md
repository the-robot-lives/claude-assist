# Kepler.gl

## What
Kepler.gl is a no-code geospatial analytics application for large-scale data visualization, delivered as a React/Redux component (and a Python/Jupyter binding). Its primary consumers are a browser React app or a Python notebook via the `keplergl` package.

## How
- In JS, the LLM emits **Kepler.gl React + Redux code** — mount `<KeplerGl id="map" mapboxApiAccessToken={...} .../>`, wire `keplerGlReducer` into a Redux store, and `dispatch(addDataToMap({datasets, config}))` with fields/rows plus a layer `config`.
- In Python, `KeplerGl(height=600, data={'data': df})` then `map.save_to_html(...)`.
- Data is loaded as typed field/row datasets; layers, filters, and time animations are configured declaratively.
- Typical final artifact: an **interactive GPU-accelerated analytics map**, exportable to an HTML file or a PNG image (`exportImageModal`).

## Why
- Reach for Kepler.gl when you want point-and-click exploration of large geospatial datasets — multiple layer types, advanced filtering, and time-series animation — with minimal code.
- Main tradeoff: it is an opinionated application (Redux store, Mapbox token) rather than a low-level library, so it is less flexible than building directly on deck.gl.
- Relative to its siblings: Kepler.gl is the no-code app built **on top of** `deck.gl`, trading deck.gl's programmability for a ready-made analytics UI; both rely on a `mapbox-gl-js`/vector base map.

## Source
- Solution reference: `fim/solution/kepler_gl.md`
