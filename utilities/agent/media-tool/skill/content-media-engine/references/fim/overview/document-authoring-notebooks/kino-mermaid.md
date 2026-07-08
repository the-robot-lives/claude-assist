# Kino.Mermaid

## What
Kino.Mermaid renders Mermaid diagrams — flowcharts, sequence diagrams, and other visual documentation — directly inside Elixir LiveBook notebooks using standard Mermaid syntax.

## How
- The LLM emits Elixir: a Mermaid diagram definition as a string passed to `Kino.Mermaid.new(graph_definition)`.
- Rendered by evaluating the LiveBook cell after adding `{:kino_mermaid, "~> 0.1.0"}`; diagrams update live during development.
- Final artifact: a rendered SVG diagram in the notebook cell output.

## Why
- Reach for Kino.Mermaid for visual documentation in LiveBook — system architecture and process flows, notebook presentations, and learning materials — using familiar Mermaid syntax with pure Elixir integration (no JavaScript).
- Tradeoffs: LiveBook-only, static output (no interactive diagram features), and more limited styling than full Mermaid.
- It is the diagramming member of the Kino family; it wraps the same Mermaid DSL covered elsewhere in the catalog, scoped to the LiveBook runtime.

## Source
- Solution reference: `fim/solution/kino-mermaid.md`
