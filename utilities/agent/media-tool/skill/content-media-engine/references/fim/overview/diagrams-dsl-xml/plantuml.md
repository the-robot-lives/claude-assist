# PlantUML

## What
PlantUML is a text-based UML diagram generator with extensive diagram-type support — sequence, class, activity, component, state, and 14+ types in total. It produces rendered UML images and is consumed via IDE extensions, an npm package, an online editor, or a local Java-based server.

## How
- The LLM emits PlantUML text markup wrapped in `@startuml ... @enduml`, using arrow syntax for messages, notes, and async signals.
- That markup is turned into a viewable artifact through the VS Code extension (`ext install jebbs.plantuml`), the `node-plantuml` npm package, or the online editor at plantuml.com. Local rendering requires a Java runtime or server.
- Typical final artifact: rendered raster/vector UML diagram image (PNG/SVG), embeddable in GitHub, GitLab, and Confluence.

## Why
- Reach for PlantUML when you need broad UML coverage with extensive theming/styling in a version-control-friendly text format backed by a large, active community — best for `sequence-diagrams`, `class-diagrams`, `architecture-documentation`, and `technical-specs`.
- Limitations: auto-layout can produce suboptimal results, limited control over exact positioning, syntax can be verbose for complex diagrams, and local rendering requires a Java runtime or server.
- Relative to Mermaid (its closest sibling): PlantUML covers the full UML spec and richer theming, whereas Mermaid is lighter-weight and renders natively in GitHub/GitLab without a Java dependency.

## Source
- Solution reference: `fim/solution/plantuml.md`
- Nested use-case detail: `fim/solution/plantuml/use-case/diagram-generation.md`
