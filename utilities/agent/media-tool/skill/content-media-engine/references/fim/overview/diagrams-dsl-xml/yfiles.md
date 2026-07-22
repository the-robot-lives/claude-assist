# yFiles for HTML

## What
yFiles for HTML is a professional, commercially licensed graph-visualization library with sophisticated automatic layout algorithms and rich interactions. It is consumed as a JavaScript library embedded in web applications and targets enterprise-grade diagramming.

## How
- The LLM emits JavaScript that drives the yFiles API — instantiating a `GraphComponent`, setting an input mode, creating nodes/edges with styles, and applying an automatic layout (e.g. `HierarchicLayout`) via `morphLayout`.
- That code is turned into a viewable artifact by installing the library (`npm install yfiles`, commercial license required and set via `License.value`) and mounting the `GraphComponent` onto a DOM element in the browser.
- Typical final artifact: an interactive, high-performance in-browser diagram (handles 10K+ elements) with editing and rich interaction features.

## Why
- Reach for yFiles when you need industry-leading layouts, high performance at scale, deep customization, and professional support — best for enterprise visualization, network-management tools, CAD applications, and business-process modeling.
- Limitations: expensive licensing, a complex API, and a heavy framework footprint.
- Relative to the text-DSL siblings in this category: yFiles is a programmatic, interaction-first commercial library, not a lightweight author-once text format — you reach for it when interactivity and layout quality at scale matter more than plain-text simplicity.

## Source
- Solution reference: `fim/solution/yfiles.md`
