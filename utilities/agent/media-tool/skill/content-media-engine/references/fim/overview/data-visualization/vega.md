# Vega

## What
Vega is a declarative visualization grammar: a full JSON specification language for creating, saving, and sharing graphics in the browser. Specs describe data, scales, and marks explicitly, making visualizations reproducible.

## How
- The LLM emits a Vega JSON spec (`$schema`, `data`, `scales`, `marks`, ...).
- Rendered by installing `vega` (v5.30.0 via npm) or loading the CDN bundle, then `new vega.View(vega.parse(spec)).renderer('canvas').initialize('#vis').run()`. Server-side rendering is supported.
- Final artifact: a chart rendered to Canvas or SVG from the parsed spec.

## Why
- Reach for Vega when you want fully declarative, reproducible, JSON-based graphics for data pipelines, automated reporting, and grammar-based statistical visualization — extensible via transforms.
- Tradeoffs: specifications are verbose, the grammar has a real learning curve, 3D support is limited, and debugging can be difficult.
- Versus Vega-Lite it is lower-level and more verbose but more powerful; Vega-Lite compiles down to Vega for simpler authoring.

## Source
- Solution reference: `fim/solution/vega.md`
