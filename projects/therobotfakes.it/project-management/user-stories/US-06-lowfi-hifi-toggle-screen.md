# US-06 — Low-fi / high-fi toggle for a whole screen

**As** the solo founder (`solo-founder-validating`)
**I want** a single switch that flips a screen from rough low-fi sketch to fully themed high-fi mockup,
**so that** I go from sketch to a pitch-worthy mockup with no rework in between.

**Priority:** P0  **Size:** S

## Acceptance criteria
- One toggle changes the render mode of the entire screen.
- High-fi applies the CSS generated from `theme.yaml`; the same elements gain real type, color, and spacing.
- No DSL edits are required to switch modes — the source is identical in both.
- Toggling back to low-fi restores the rough rendering exactly.
- Switching modes does not alter the canonical text source.

## Notes / linked README concept
§3 the low-fi/high-fi toggle. "You never redraw; you upvert" — the signature one-switch transition.
