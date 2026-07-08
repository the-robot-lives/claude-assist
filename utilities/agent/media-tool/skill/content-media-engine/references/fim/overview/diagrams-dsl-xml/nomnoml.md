# nomnoml

## What
nomnoml is a minimalist UML sketch tool with a hand-drawn aesthetic, focused mainly on class and simple flowchart diagrams. It is consumed via an npm package, a browser CDN script, a VS Code extension, or its online editor.

## How
- The LLM emits nomnoml text markup — styling directives (`#direction`, `#spacing`, `#fill`, etc.) plus bracketed nodes and typed classifiers like `[<actor> User| ... ]` and association arrows.
- That markup is turned into a viewable artifact via `npm install nomnoml`, the `unpkg.com/nomnoml` CDN script, the VS Code extension, or the editor at nomnoml.com.
- Typical final artifact: lightweight rendered diagram with a sketch/hand-drawn rendering style.

## Why
- Reach for nomnoml when you want fast, attractive, low-ceremony diagrams for conceptual work — best for `quick-sketches`, `conceptual-diagrams`, `class-diagrams`, `simple-flowcharts`, and `documentation-visuals`.
- Limitations: limited diagram types (mainly class and flowchart), no sequence-diagram support, basic styling compared to other tools, and a small ecosystem/community.
- Relative to the fuller-UML siblings (PlantUML, yUML): nomnoml trades breadth for a clean minimalist syntax and a distinctive hand-drawn look.

## Source
- Solution reference: `fim/solution/nomnoml.md`
