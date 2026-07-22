# HERE Maps

## What
HERE Maps is a commercial location platform offering interactive maps plus geocoding, routing, and traffic services via a browser JavaScript SDK. Its primary consumer is client-side browser JavaScript, initialized through the `H.service.Platform` object with an API key.

## How
- The LLM emits **HERE Maps JavaScript** — `new H.service.Platform({apikey})`, then `platform.createDefaultLayers()` and `new H.Map(element, layers.vector.normal.map, {zoom, center})`.
- That runs in the browser: map behavior/UI are wired with `H.mapevents.Behavior` and `H.ui.UI.createDefault`; markers (`H.map.Marker`), geocoding (`platform.getSearchService()`), and routing (`platform.getRoutingService()`) add functionality.
- Requires an API key from developer.here.com.
- Typical final artifact: an **interactive in-browser map** backed by HERE's tile and services platform.

## Why
- Reach for HERE when the emphasis is logistics and mobility — real-time traffic flow, public-transit and isoline routing, fleet telematics, and indoor maps — in a commercial application.
- Main tradeoff: like other commercial platforms it is API-key-gated and usage-billed, and has a smaller developer footprint than Google Maps.
- Relative to its siblings: HERE is the routing/fleet-focused peer of `google-maps-api` among commercial platforms, and contrasts with the open-source `leaflet_js`/`maplibre-gl-js`/`openlayers` stack.

## Source
- Solution reference: `fim/solution/here-maps.md`
