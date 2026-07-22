# GeoGebra API

## What
The GeoGebra API embeds GeoGebra's interactive mathematics applets (graphing, geometry, 3D, CAS) into a web page, driven by GeoGebra command strings. Its primary consumer is browser JavaScript, loaded from GeoGebra's hosted `deployggb.js`.

## How
- The LLM emits **GeoGebra API JavaScript** — configure `GGBApplet({appName: 'graphing'|'geometry'|'3d'|'cas', width, height, appletOnLoad})` and `.inject('ggb-applet')`.
- That runs in the browser: objects are built with `api.evalCommand("f(x) = x^2 - 3x + 2")`, `Line(A, B)`, `Slider(...)`, `Intersect(...)`, `Tangent(...)`; properties set via `setColor`/`setPointSize`; values read via `getValue`/`getXcoord`. 3D mode via `api.setPerspective("3d")` with `Sphere`, planes, and space curves.
- Typical final artifact: an **interactive in-browser math applet** spanning 2D graphing, dynamic geometry, CAS, and 3D.

## Why
- Reach for GeoGebra when you need a full dynamic-mathematics environment — construction-based geometry, sliders driving live constructions, CAS, and 3D — rather than just function graphing.
- Main tradeoff: it is a large hosted applet suite; heavier and more general than a focused graphing widget.
- Relative to its siblings: GeoGebra is the broadest of the three interactive-math tools — `desmos-api` specializes in the 2D graphing calculator, and `jsxgraph` is a lighter, self-hostable geometry/plotting library.

## Source
- Solution reference: `fim/solution/geogebra-api.md`
