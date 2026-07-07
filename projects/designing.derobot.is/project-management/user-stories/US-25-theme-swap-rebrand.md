# US-25 — Swap themes to instantly rebrand

**As** the agency consultant (`agency-consultant-demos`)
**I want** to swap a project's `theme.yaml` seed tokens to re-skin all screens to a client's brand at once,
**so that** I can rebrand a reusable demo library per client without redoing any styling.

**Priority:** P2  **Size:** S

## Acceptance criteria
- A project can switch between multiple named `theme.yaml` token sets.
- Swapping the theme regenerates CSS and updates every high-fi screen consistently.
- The DSL/text sources of screens are unchanged by a theme swap.
- A new theme can be created from a handful of seed tokens (fonts, colors, gap scale, radii).
- Subtree-scoped themes (US-08) are respected and not overridden by the project default.

## Notes / linked README concept
§2 "You write ~12 values; the engine derives hundreds" applied to per-client rebranding (persona Marcus).
