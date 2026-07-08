# Draw.io XML Format

## What
Draw.io (diagrams.net) XML is the native file format for creating professional technical diagrams, architectural visualizations, and collaborative documentation. It is consumed by the draw.io desktop apps, VS Code and JetBrains editor integrations, and programmatic export libraries/CLIs.

## How
- The LLM emits draw.io XML — an `<mxfile>` wrapper containing one or more `<diagram>` pages, each holding an `<mxGraphModel>` with `<root>` and `<mxCell>` elements for shapes and edges (styles carried as attributes; shape libraries for AWS, UML, and network topology are available).
- That XML is turned into a viewable/editable artifact by opening it in the draw.io desktop app (`brew install --cask drawio`, `winget install JGraph.Draw.io`, Snap/AppImage), the VS Code extension (`ext install hediet.vscode-drawio`), or export tooling such as `@jgraph/drawio-export` and the `jgraph/export-server` Docker image.
- Typical final artifact: an editable `.drawio` diagram plus exported SVG/PNG/PDF; supports multi-page documents, layers, custom stencils, theming, and dark mode.

## Why
- Reach for draw.io XML when you want a full-featured, GUI-editable diagramming format with rich shape libraries and enterprise integrations (Confluence, GitLab CI, GitHub Actions) — strong for AWS/cloud architecture, UML, and network-topology diagrams that teams collaborate on.
- Limitations/tradeoffs: the XML is verbose and low-level (hand-authoring cell geometry is tedious), and large diagrams need explicit performance/memory optimization; it is best driven through the editor or export APIs rather than written by hand.
- Relative to the text DSL siblings (Mermaid, PlantUML): draw.io is GUI-first with a serialized XML backing store, favoring visual editing and export breadth over concise human-authored markup.

## Source
- Solution reference: `fim/solution/drawio-xml.md`
