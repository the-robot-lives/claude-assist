# Structurizr DSL

## What
Structurizr DSL is a text-based domain-specific language for creating C4-model software-architecture diagrams (Context, Container, Component, Code) from text definitions. It supports version-controlled, collaborative "architecture-as-code" and can export to multiple downstream formats.

## How
- The LLM emits a `workspace { model { ... } views { ... } }` definition — people, software systems, containers, and relationships in the model, with `systemContext`/`container` views and `autolayout` directives.
- That definition is turned into a viewable artifact via the Structurizr CLI (`npm install -g structurizr-cli`) or the Docker image, e.g. `structurizr/cli export -workspace workspace.dsl -format plantuml`.
- Typical final artifact: exported diagrams as PlantUML, Mermaid, or JSON, or rendered web visualizations.

## Why
- Reach for Structurizr DSL when you want C4-native, standards-enforcing architecture documentation kept in Git with consistent output across diagrams — best for software-architecture docs, C4 diagrams at all levels, and architecture-as-code workflows.
- Limitations: learning curve around C4 concepts, cloud workspace hosting requires a paid subscription for teams, and it is focused on software architecture rather than general diagrams.
- Relative to C4-PlantUML (its closest C4 sibling): Structurizr DSL is a purpose-built C4 language with multi-format export, whereas C4-PlantUML layers C4 macros onto an existing PlantUML setup.

## Source
- Solution reference: `fim/solution/structurizr-dsl.md`
