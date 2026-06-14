# Excalidraw - FIM Solution Documentation

## Description
[Excalidraw](https://excalidraw.com) is a virtual whiteboard producing hand-drawn, sketch-style diagrams. Its `.excalidraw` files are JSON scene documents, and the `@excalidraw/excalidraw` React component plus an export API turn scenes into SVG/PNG. The informal, approachable aesthetic is popular in developer content, architecture sketches, and explainer threads.

## Basic Syntax
```json
{
  "type": "excalidraw",
  "version": 2,
  "elements": [
    { "type": "rectangle", "x": 40, "y": 40, "width": 160, "height": 70,
      "strokeColor": "#1e1e1e", "backgroundColor": "#a5d8ff",
      "roughness": 1, "id": "client" },
    { "type": "text", "x": 70, "y": 65, "text": "Client", "fontSize": 20 }
  ],
  "appState": { "viewBackgroundColor": "#ffffff" }
}
```
```js
// Programmatic export to SVG
import { exportToSvg } from '@excalidraw/excalidraw'
const svg = await exportToSvg({ elements, appState, files: null })
```

## Toolchain
- **@excalidraw/excalidraw** - Embeddable React canvas component
- **exportToSvg / exportToBlob** - Render scenes to SVG/PNG programmatically
- **excalidraw CLI / mermaid-to-excalidraw** - Convert Mermaid into sketch scenes
- **.excalidraw files** - Portable JSON scenes (versionable, re-editable)
- **Obsidian/VS Code plugins** - Author within note/editor workflows

## Strengths
- Distinctive hand-drawn style that feels approachable
- Re-editable JSON scenes (not flattened images)
- Embeddable editor for interactive docs
- Programmatic SVG/PNG export for articles/thumbnails
- Mermaid import to "sketchify" formal diagrams

## Limitations
- Manual placement (no strong auto-layout like D2/Graphviz)
- Not ideal for precise/standardized notation (UML, ERD)
- Sketch aesthetic is stylistic — not for formal specs
- Programmatic generation is verbose vs text DSLs

## Best Use Cases
- Friendly architecture sketches for blog posts and threads
- Whiteboard-style explainer figures
- Annotated diagrams that stay editable
- Sketchified versions of formal Mermaid diagrams

## NPL-FIM Integration
```npl
⌜excalidraw-sketch|excalidraw|FIM@1.0⌝
format: excalidraw-json
render: exportToSvg | exportToBlob
import: mermaid-to-excalidraw
export: svg | png
style: hand-drawn
⌞excalidraw-sketch⌟
```

NPL agents produce Excalidraw scenes (authored or converted from Mermaid) when content benefits from an approachable, hand-drawn diagram style.
