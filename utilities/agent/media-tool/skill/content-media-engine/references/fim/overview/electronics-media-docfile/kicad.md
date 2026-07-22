# KiCad

## What
KiCad is a professional, open-source EDA suite for schematic capture and PCB design, widely treated as an industry-standard tool. It is a native desktop application whose primary consumer is the KiCad app (and its Python scripting API via `pcbnew`), producing manufacturable board files rather than inline document graphics.

## How
- **LLM emits:** KiCad project files (`project.kicad_pro`, `project.kicad_sch`, `project.kicad_pcb`) plus Python automation scripts using the `pcbnew` module (e.g. `board = pcbnew.LoadBoard("design.kicad_pcb")`).
- **Render path:** open the project in KiCad, or drive it programmatically through the `pcbnew` Python API to inspect/modify the board; export production and visualization outputs from there.
- **Typical final artifact:** Gerber (fabrication), STEP/VRML (3D/mechanical), and SVG (documentation), targeting the KiCad v6 format.

## Why
- **Reach for it when:** you need professional-grade schematic-to-PCB design, 3D board visualization, extensive component libraries, Python scripting, and real Gerber generation for manufacturing.
- **Limitations:** steep learning curve, overkill for simple tasks, a large installation footprint, and no built-in circuit simulation.
- **Relative to siblings:** KiCad is the professional end of the EDA spectrum versus Fritzing's maker-friendly visual approach — choose KiCad when the deliverable is a fabricable multi-layer board, Fritzing when the deliverable is an approachable breadboard diagram.

## Source
- Solution reference: `fim/solution/kicad.md`
