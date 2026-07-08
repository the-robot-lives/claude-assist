# Mermaid

## What
Mermaid is a text-based diagramming tool (JavaScript library) that renders flowcharts, sequence diagrams, Gantt charts, class/state/ER diagrams, git-workflows and more from a markdown-inspired text syntax. Its primary consumer is browser JavaScript, with native rendering support inside GitHub, GitLab, and Notion.

## How
- The LLM emits Mermaid text markup (e.g. a `graph LR` flowchart or `sequenceDiagram` block).
- That markup is turned into a viewable artifact by dropping it into a `<div class="mermaid">` element and calling `mermaid.initialize({ startOnLoad: true })`, or by placing it in a fenced ` ```mermaid ` block in Markdown on a platform (GitHub/GitLab) that renders it automatically. Install via `npm install mermaid` for Node, or the jsDelivr CDN script for the browser.
- Typical final artifact: inline SVG rendered in the browser (basic tooltips supported).

## Why
- Reach for Mermaid when you want version-control-friendly, plain-text diagrams that render natively in documentation platforms with no external dependencies or design tooling — ideal for `documentation`, `flowcharts`, `sequence-diagrams`, `gantt-charts`, and `git-workflows`.
- Limitations: limited styling customization, layout algorithms that sometimes produce suboptimal results, and no interactive features beyond basic tooltips.
- Relative to PlantUML (its closest sibling): Mermaid is text-first and GitHub-native for quick prototyping, whereas PlantUML covers the fuller UML spec at the cost of a Java runtime.

## Source
- Solution reference: `fim/solution/mermaid.md`
- Nested use-case detail: `fim/solution/mermaid/use-case/diagram-generation.md`, `fim/solution/mermaid/use-case/networks-graphs.md`
