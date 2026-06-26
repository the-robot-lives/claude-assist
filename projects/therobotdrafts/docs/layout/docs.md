# layout/docs.md — `docs/`

The design corpus. The Robot Draft is spec-first: architecture, concepts, decision records, and
feature/format specifications that the Unity stub is gradually realizing.

```
docs/
├── ARCHITECTURE.md             # System architecture overview
├── CONCEPTS.md                 # Domain concepts & glossary (bubbles, reverse-engineering, projections)
├── PROJ-LAYOUT.md              # Navigable project map (top level)
├── PROJ-LAYOUT.summary.md      # Tree-only companion to PROJ-LAYOUT.md (keep in sync)
├── adrs/                       # Architecture Decision Records
│   ├── ADR-001-unity-dots-rendering.md       # DOTS / GPU-driven render pipeline
│   ├── ADR-002-unified-internal-model.md      # One unified model behind all diagram families
│   └── ADR-003-sphere-packing-bubble-layout.md # Sphere-packing for nested bubble layout
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
