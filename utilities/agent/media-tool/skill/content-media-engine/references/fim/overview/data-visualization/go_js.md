# GoJS

## What
GoJS is a feature-rich commercial JavaScript library for building interactive diagrams, flowcharts, and complex graphs in the browser. It is template-driven (node and link templates) with a data model, built-in undo/redo, and touch support.

## How
- The LLM emits browser JavaScript: `import * as go from 'gojs'`, create a `go.Diagram` on a div, define `nodeTemplate`/`linkTemplate` via `go.GraphObject.make`, and assign a `go.GraphLinksModel` of node and link data.
- Rendered by installing `gojs` via npm (production use requires a license) and mounting the diagram on a target `<div>`.
- Final artifact: an interactive, editable diagram/graph in the DOM.

## Why
- Reach for GoJS for enterprise diagramming — BPMN diagrams, org charts, complex flowcharts, and commercial products — where professional templates, built-in undo/redo, and strong documentation matter.
- Tradeoffs: a commercial license is required, the library is large, and the API is proprietary.
- Within this category it sits at the diagram/graph-editor end rather than the statistical-charting end; for pure charts, Chart.js/ECharts fit better.

## Source
- Solution reference: `fim/solution/go_js.md`
