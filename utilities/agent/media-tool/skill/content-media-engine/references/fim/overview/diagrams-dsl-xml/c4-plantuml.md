# C4-PlantUML

## What
C4-PlantUML is a PlantUML standard library that combines PlantUML's text-based diagramming with the C4 model for software-architecture visualization. It supports all four C4 abstraction levels — Context, Container, Component, and Code — and renders through the PlantUML engine.

## How
- The LLM emits PlantUML markup that `!include`s a C4 stdlib file (e.g. `C4_Context.puml` or `C4_Container.puml`, remotely from the plantuml-stdlib GitHub raw URL or a local include) and uses C4 macros like `Person()`, `System_Boundary()`, `Container()`, `ContainerDb()`, and `Rel()`.
- That markup is turned into a viewable artifact by PlantUML's rendering engine (same setup as PlantUML: IDE extension, npm package, or server).
- Typical final artifact: rendered C4 architecture diagram image (PNG/SVG), suited to Markdown/AsciiDoc docs and CI/CD documentation pipelines.

## Why
- Reach for C4-PlantUML when you want standardized C4 notation and are already using PlantUML — good for software-architecture documentation, system design reviews, and teams with existing PlantUML pipelines.
- Limitations: requires PlantUML knowledge and setup, is limited to C4 model abstractions, has no interactive features, and manual layout can be challenging for complex diagrams.
- Relative to Structurizr DSL (its closest C4 sibling): C4-PlantUML layers C4 onto the PlantUML ecosystem you already run, whereas Structurizr DSL is a purpose-built C4 language that can export to PlantUML/Mermaid/JSON.

## Source
- Solution reference: `fim/solution/c4-plantuml.md`
