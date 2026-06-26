# layout/docs.md — `docs/`

The design corpus. The Robot Draft is spec-first: architecture, concepts, decision records, and
feature/format specifications that the Unity stub is gradually realizing.

```
docs/
├── ARCHITECTURE.md             # System architecture overview (long-form)
├── CONCEPTS.md                 # Domain concepts & glossary (bubbles, reverse-engineering, projections)
├── PROJ-ARCH.md                # Navigable architecture map (top level) → arch/* detail files
├── PROJ-ARCH.summary.md        # Tree-only companion to PROJ-ARCH.md
├── PROJ-LAYOUT.md              # Navigable project map (top level)
├── PROJ-LAYOUT.summary.md      # Tree-only companion to PROJ-LAYOUT.md (keep in sync)
├── sparx-ea-parity.md          # Feature-parity checklist vs. Sparx Enterprise Architect
├── ux-review-current-build.md  # UX review of the current playable build
├── adrs/                       # Architecture Decision Records
│   ├── ADR-001-unity-dots-rendering.md       # DOTS / GPU-driven render pipeline
│   ├── ADR-002-unified-internal-model.md      # One unified model behind all diagram families
│   └── ADR-003-sphere-packing-bubble-layout.md # Sphere-packing for nested bubble layout
├── arch/                       # Architecture detail files (linked from PROJ-ARCH.md)
│   ├── unified-model.md         #   The single internal model behind every diagram family
│   ├── ingestion.md             #   Ingestion & reverse engineering frontends
│   ├── layout.md                #   Layout engine (packing, regions, Z-layers)
│   ├── projection-and-interchange.md  # Diagram projection & interchange formats
│   ├── rendering-and-vr.md      #   Render pipeline & VR
│   ├── data-flow.md             #   Data flow & code↔model round-trip
│   ├── decisions.md             #   Key architectural decisions (narrative companion to adrs/)
│   └── implementation-status.md #   Designed vs. built tracker
├── specs/                      # Feature & format specifications
│   ├── authoring-ux.md         #   Authoring interaction model (affordances, §-referenced by code)
│   ├── design-conventions.md   #   Cross-cutting design conventions
│   ├── diagram-catalog.md      #   Supported diagram families (UML/SysML/BPMN/ERD/ArchiMate…)
│   ├── file-formats.md         #   On-disk model / diagram formats
│   ├── rendering-and-vr.md     #   Rendering pipeline & VR interaction
│   ├── reverse-engineering.md  #   Code/binary → model frontends & decompilers
│   ├── unity-6.3-baseline.md   #   Unity 6.3 baseline feature set
│   └── unity-6.5-delta.md      #   Deltas adopted from Unity 6.5
├── layout/                     # This directory — PROJ-LAYOUT detail files
│   ├── assets.md
│   ├── scripts.md
│   └── docs.md
└── diagrams/                   # (empty) exported diagram assets
```

## Notes

- `specs/authoring-ux.md` is the source of the `§`-section references throughout `Assets/Scripts/Uml/`
  and `Authoring/` (e.g. §3.1 containment filtering, §4.2 arrowheads, §B invalid affordance).
- Two doc-map pairs live here: `PROJ-ARCH.md`/`.summary.md` (architecture, detailed in `arch/`) and
  `PROJ-LAYOUT.md`/`.summary.md` (structure, detailed in `layout/`). Keep each summary in sync.
- `arch/decisions.md` is the narrative decision log; `adrs/` holds the formal numbered records.
