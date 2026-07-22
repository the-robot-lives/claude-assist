# Desmos API

## What
The Desmos API embeds Desmos's interactive graphing calculator into a web page, driven by LaTeX expressions. Its primary consumer is browser JavaScript, loaded from Desmos's hosted `calculator.js` with an API key.

## How
- The LLM emits **Desmos API JavaScript** — load the script, then `Desmos.GraphingCalculator(elt, {keypad, expressions, zoomButtons, ...})` on a sized `<div>`.
- That runs in the browser: expressions are added with `calculator.setExpression({id, latex: 'y = x^2 + 2x - 3', color})`, including parametric forms, labeled points, and sliders (`sliderBounds`); state can be saved/restored via `getState`/`setState`.
- A raster export is available via `calculator.screenshot({...}, dataUri => ...)`.
- Typical final artifact: an **interactive in-browser graphing calculator**, or a PNG screenshot (data URI).

## Why
- Reach for the Desmos API when you want a polished, student-friendly interactive graphing calculator with sliders and a built-in keypad embedded in a web page.
- Main tradeoff: it is an API-key-gated hosted widget focused on 2D function graphing, not a general geometry system or offline library.
- Relative to its siblings: Desmos is the graphing-calculator specialist; `geogebra-api` is the broader dynamic-geometry/CAS/3D suite, and `jsxgraph` is the lighter, self-hostable interactive-geometry library.

## Source
- Solution reference: `fim/solution/desmos-api.md`
