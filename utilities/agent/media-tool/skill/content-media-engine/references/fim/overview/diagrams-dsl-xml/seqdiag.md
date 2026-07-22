# seqdiag

## What
seqdiag is a UML sequence-diagram generator in the blockdiag toolkit that produces clean sequence diagrams from a minimalist text syntax. It is consumed via a Python CLI/package and outputs PNG, SVG, or PDF.

## How
- The LLM emits seqdiag text markup — a `seqdiag { ... }` block declaring actors and their interactions with labeled messages (`browser -> server [label = "HTTP Request"]`), `return =` responses, and optional `activate`/`deactivate` lifelines.
- That markup is turned into a viewable artifact via `pip install seqdiag` (optional `pillow`, `reportlab`) and the CLI, e.g. `seqdiag input.seq -T svg -o output.svg`.
- Typical final artifact: PNG/SVG/PDF sequence diagram following standard UML conventions.

## Why
- Reach for seqdiag when you want quick, clean, standard UML sequence diagrams with minimal markup that fit documentation pipelines — best for UML/API documentation, system-design component interactions, quick prototyping, and print docs.
- Limitations: basic styling, image-generation only (no interactive/web rendering), lacks advanced UML features like fragments, requires a Python environment, and produces static output.
- Relative to its family siblings and to PlantUML: seqdiag is the sequence-diagram specialization of the blockdiag engine — lighter than PlantUML's sequence support but without fragments or richer styling.

## Source
- Solution reference: `fim/solution/seqdiag.md`
