# actdiag

## What
actdiag is an activity-diagram generator in the blockdiag family that creates process-flow diagrams — activities, decisions, and transitions — from simple text syntax. It is consumed via a Python CLI/package and produces clean SVG, PNG, or PDF output with automatic layout.

## How
- The LLM emits actdiag text markup — an `actdiag { ... }` block with an activity chain (`A -> B -> C`) and `lane` blocks that place labeled activities into swimlanes.
- That markup is turned into a viewable artifact by installing `pip install actdiag` (optional `actdiag[pdf]` and `Pillow` for PDF/PNG) and running the rendering pipeline, e.g. `actdiag diagram.diag -T svg -o output.svg`.
- Typical final artifact: SVG/PNG/PDF activity diagram with automatic positioning and routing.

## Why
- Reach for actdiag when you want simple text-based activity/process flows with swimlane support that drop into documentation pipelines — best for business-process documentation, workflow specifications, and process standardization.
- Limitations: basic feature set versus specialized tools, limited customization, no interactive elements, simple styling, and fixed layout algorithms.
- Relative to its family siblings: actdiag is the activity/swimlane specialization of the blockdiag engine, distinct from seqdiag (sequence) and nwdiag (network).

## Source
- Solution reference: `fim/solution/actdiag.md`
