# Diagrams — DSL / XML

Text- and XML-based diagramming and UML solutions where the LLM emits a declarative source (a terse DSL, a UML/architecture notation, or a serialized XML model) that a CLI, library, or editor renders to a viewable artifact — typically SVG, PNG, or PDF. They share a version-control-friendly, author-once workflow: describe the diagram in text, render deterministically, embed the result in docs.

## Solutions

### Mermaid
Text-based JavaScript diagramming for flowcharts, sequence, Gantt, class/state/ER, and git diagrams from markdown-inspired syntax. Renders as inline SVG in the browser or natively in GitHub/GitLab/Notion — no build step. Pick it when you want zero-dependency diagrams that render where your docs already live. [Detail](diagrams-dsl-xml/mermaid.md)

### PlantUML
Text-based UML generator covering 14+ diagram types with extensive theming, rendered to PNG/SVG via an IDE extension, npm package, or Java server. Pick it over Mermaid when you need full UML-spec breadth and richer styling and can accept a Java runtime for local rendering. [Detail](diagrams-dsl-xml/plantuml.md)

### C4-PlantUML
A PlantUML standard library that adds C4-model macros (`Person`, `Container`, `Rel`) for software-architecture diagrams across all four C4 levels, rendered through the PlantUML engine. Pick it when your team already runs PlantUML and wants standardized C4 notation without a new toolchain. [Detail](diagrams-dsl-xml/c4-plantuml.md)

### Graphviz
The industry-standard graph-visualization software with multiple automatic layout engines (dot, neato, fdp, circo, twopi), consumed via CLI or Python/JS bindings. Pick it for robust auto-layout of large node-and-edge graphs — dependency graphs, state machines, call graphs. [Detail](diagrams-dsl-xml/graphviz.md)

### Graphviz DOT Language
The declarative DOT language itself — nodes, edges, subgraphs, and attributes — that Graphviz's engines consume and many other tools also accept. Pick it (vs. the Graphviz entry) when you care about the portable input format for automated generation rather than the renderer. [Detail](diagrams-dsl-xml/graphviz-dot.md)

### nomnoml
Minimalist UML sketch tool with a distinctive hand-drawn aesthetic, focused on class and simple flowchart diagrams, run via npm/CDN/VS Code or its web editor. Pick it for fast, attractive conceptual sketches when you don't need sequence diagrams or heavy styling. [Detail](diagrams-dsl-xml/nomnoml.md)

### Structurizr DSL
A purpose-built C4 architecture-as-code language (`workspace { model {} views {} }`) that exports to PlantUML, Mermaid, JSON, or web views via a CLI/Docker. Pick it over C4-PlantUML when you want a dedicated C4 language with multi-format export and enforced consistency. [Detail](diagrams-dsl-xml/structurizr-dsl.md)

### XMI (XML Metadata Interchange)
An OMG-standard XML format for exchanging full UML models/metamodels between modeling tools (StarUML, Enterprise Architect, MagicDraw, etc.). Pick it for tool interoperability and MDA workflows — moving models between tools — not for quickly sketching a single picture. [Detail](diagrams-dsl-xml/uml-xmi.md)

### yUML
A zero-install online service that turns short text into class, activity, and use-case diagrams via URL-based image endpoints embeddable in any HTML/Markdown. Pick it for the lightest-weight, no-setup diagrams in READMEs or blog posts, accepting that it always requires internet access. [Detail](diagrams-dsl-xml/yuml.md)

### Draw.io XML Format
The native `<mxfile>`/`<mxGraphModel>` XML behind diagrams.net, edited in desktop/VS Code apps and exported to SVG/PNG/PDF, with rich AWS/UML/network shape libraries and enterprise integrations. Pick it for GUI-first, collaborative diagrams with deep shape libraries — best driven through the editor rather than hand-authored. [Detail](diagrams-dsl-xml/drawio-xml.md)

### BPMN XML
The OMG BPMN 2.0 XML format for process diagrams that are not just drawn but executable on engines like Camunda, Activiti, or jBPM. Pick it when a business process must be both documented and run to an industry standard, with gateways, subprocesses, and events. [Detail](diagrams-dsl-xml/bpmn-xml.md)

### yFiles for HTML
A commercially licensed JavaScript library with industry-leading automatic layouts and rich interactivity, handling 10K+ elements in-browser. Pick it when interactivity, layout quality, and scale matter more than plain-text simplicity — enterprise network/CAD/BPM tooling — and the license cost is acceptable. [Detail](diagrams-dsl-xml/yfiles.md)

### Blockdiag
The root of the blockdiag Python family: minimal `blockdiag { }` syntax for box-and-arrow diagrams with automatic layout, output to PNG/SVG/PDF. Pick it for simple architecture/component/infrastructure diagrams; reach for a family sibling below when your diagram is a specific type. [Detail](diagrams-dsl-xml/blockdiag.md)

### actdiag
The blockdiag family's activity-diagram specialization, adding swimlane `lane` blocks over an activity chain, rendered to SVG/PNG/PDF via `pip install actdiag`. Pick it for simple, documentation-friendly process/workflow flows with lanes. [Detail](diagrams-dsl-xml/actdiag.md)

### nwdiag
The blockdiag family's network-topology specialization, grouping devices into `network` segments with address ranges, output to PNG/SVG/PDF/PostScript. Pick it for multi-subnet network-architecture documentation with simple, maintainable syntax. [Detail](diagrams-dsl-xml/nwdiag.md)

### packetdiag
The blockdiag family's packet/protocol specialization, mapping bit ranges to field labels for standards-grade packet-format diagrams (CLI or Python API). Pick it for RFC/protocol documentation and networking education needing bit-level precision. [Detail](diagrams-dsl-xml/packetdiag.md)

### rackdiag
The blockdiag family's datacenter specialization, placing equipment at accurate U-positions for server-rack layouts, rendered via `rackdiag diagram.rack -f PNG`. Pick it for rack-unit-accurate infrastructure and capacity-planning diagrams. [Detail](diagrams-dsl-xml/rackdiag.md)

### seqdiag
The blockdiag family's UML sequence-diagram specialization, with labeled messages, returns, and lifeline activation, output to PNG/SVG/PDF. Pick it for quick, clean, standard sequence diagrams in docs; choose PlantUML instead if you need fragments or richer styling. [Detail](diagrams-dsl-xml/seqdiag.md)

## Source
- Detail files: `fim/overview/diagrams-dsl-xml/*.md` (18 solutions)
- Underlying solution references: `fim/solution/{solution}.md`
