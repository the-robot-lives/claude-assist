# US-04 — Live low-fi render in the editor

**As** the solo founder (`solo-founder-validating`)
**I want** the canvas to render my DSL as a deliberately rough low-fi sketch as I type,
**so that** I can judge structure and intent immediately without bikeshedding pixels.

**Priority:** P0  **Size:** S

## Acceptance criteria
- The split-view Editor renders the parse tree on the right as I edit text on the left.
- Low-fi styling is intentionally rough: sketch borders, placeholder grays, lorem affordances.
- Render updates within a perceptible-instant debounce after a valid edit.
- A parse error leaves the last valid render visible plus an inline error indicator.
- Low-fi mode requires no `theme.yaml` to render.

## Notes / linked README concept
§3 low-fi mode + Key Pages "Editor" (split view, live canvas). The fast feedback half of the core loop.
