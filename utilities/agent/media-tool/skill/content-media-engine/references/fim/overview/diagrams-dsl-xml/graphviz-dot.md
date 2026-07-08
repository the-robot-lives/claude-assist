# Graphviz DOT Language

## What
The Graphviz DOT language is a domain-specific language for declaratively defining graph structures — nodes, edges, subgraphs, and their attributes. It is the input format consumed by Graphviz's layout engines and portable across many other visualization tools.

## How
- The LLM emits DOT markup (e.g. `strict digraph Pipeline { ... }`), optionally with graph/node/edge attribute blocks, `subgraph cluster_*` groupings, and `{rank=same; ...}` rank alignment.
- That markup is turned into a viewable artifact by rendering it with Graphviz (`brew install graphviz`), a VS Code extension (`ext install joaompinto.vscode-graphviz`), or online editors such as GraphvizOnline / webgraphviz.
- Typical final artifact: rendered graph image (SVG/PNG/PDF); output varies significantly with the chosen layout algorithm.

## Why
- Reach for DOT when you want a simple, readable, portable declaration of a graph with a powerful attribute system — best for `ast-visualization`, `database-schemas`, `infrastructure-topology`, `workflow-diagrams`, and `hierarchy-trees`, and especially for automated diagram generation.
- Limitations: pure declaration with no conditional logic, output highly sensitive to layout-algorithm choice, restricted to graph structures, and no built-in support for non-graph diagrams.
- Relative to Graphviz (its closest sibling): DOT is the language/format, while `graphviz` is the rendering software and layout engines that consume it.

## Source
- Solution reference: `fim/solution/graphviz-dot.md`
