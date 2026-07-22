# Constraint Checklist — US-{NNN}: {title}

- **Status**: ☐ DRAFT ☐ **FROZEN** on {date} (immutable after freeze; deviations append-only below)
- **Binding**: ☐ FULL ☐ DEGRADED (no style guide found — floor + persona constraints only)
- **Style sources found**: {files, e.g. design/theme/theme-x/style-guide.vars.yaml; branding.yaml} or NONE
- **Personas bound**: {P-XXX name (level), P-XXX name (level)}
- **Surface in scope**: {screens / component types / copy / motion this story touches}

## Constraints

Precedence ranks: 1 acceptance criteria · 2 accessibility floor · 3 persona · 4 style guide · 5 screen/component inventory · 6 convention. Higher rank wins conflicts.

### Accessibility Floor (AF-*) — never overridden by style guide

| ID | Constraint | Pass condition | Ticked (evidence) |
|----|-----------|----------------|--------------------|
| AF-1 | 0 critical/serious axe violations on touched surface | axe scan | ☐ |
| AF-2 | Contrast ≥4.5:1 body / ≥3:1 large-UI, all color modes | measured | ☐ |
| AF-3 | Full keyboard operability + visible focus order | manual walkthrough | ☐ |
| AF-4 | Accessible names/labels on interactive elements | screen-reader pass | ☐ |
| AF-5 | `prefers-reduced-motion` respected | media-query check | ☐ |

### Persona Constraints (PC-*)

| ID | Constraint | Source (persona §section) | Pass condition | Ticked (evidence) |
|----|-----------|---------------------------|----------------|--------------------|
| PC-1 | | P-{XXX} §{Goals/Frustrations/JTBD/Technical Level} | | ☐ |
| PC-2 | | | | ☐ |

### Style-Guide Constraints (SG-*)

| ID | Constraint | Source (file:key/section) | Pass condition | Ticked (evidence) |
|----|-----------|---------------------------|----------------|--------------------|
| SG-1 | | | | ☐ |
| SG-2 | | | | ☐ |

## Conflict Log (resolved at binding)

| Conflict | Sources (ranks) | Winner | Rationale |
|----------|-----------------|--------|-----------|
| | | | |

## Deviation Log (append-only during phases 4–5)

| Date | Constraint | Deviation | Justification | Verdict (justified / fix-required / fixed) |
|------|-----------|-----------|---------------|--------------------------------------------|
| | | | | |

## Upstream Notes (style guide gaps/errors found — file with guide owner, do not edit the guide)

- {note or none}
