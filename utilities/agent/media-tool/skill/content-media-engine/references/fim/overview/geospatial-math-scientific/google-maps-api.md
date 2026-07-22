# Google Maps API

## What
The Google Maps API is Google's browser-based JavaScript mapping platform, providing interactive maps plus a broad set of location services (geocoding, directions, Places, drawing, Street View). Its primary consumer is client-side browser JavaScript loaded from Google's hosted script with an API key.

## How
- The LLM emits **Google Maps init JavaScript** — a `<script src="https://maps.googleapis.com/maps/api/js?key=...&callback=initMap">` tag plus an `initMap()` function.
- That runs in the browser: `new google.maps.Map(element, {center, zoom, mapTypeId})` creates the map; markers (`google.maps.Marker`), info windows, directions (`DirectionsService`/`DirectionsRenderer`), Places (`PlacesService`), and drawing tools are layered on.
- Requires an API key from the Google Cloud console.
- Typical final artifact: an **interactive in-browser map** backed by Google's tile and services infrastructure.

## Why
- Reach for Google Maps when you need Google's data and services out of the box — real-time traffic, geocoding, Places autocomplete, distance matrix, Street View — in a commercial web app.
- Main tradeoff (implicit in its hosted/keyed model): it is a paid, API-key-gated Google service rather than an open self-hostable library, so it carries usage billing and vendor lock-in versus open alternatives.
- Relative to its siblings: it is the batteries-included commercial counterpart to `here-maps` (another commercial location platform) and stands opposite `leaflet_js`/`maplibre-gl-js`, which are open-source and provider-agnostic.

## Source
- Solution reference: `fim/solution/google-maps-api.md`
