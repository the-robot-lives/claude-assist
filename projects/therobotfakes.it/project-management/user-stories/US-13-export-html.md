# US-13 — Export static, self-contained HTML

**As** the solo founder (`solo-founder-validating`)
**I want** to export a screen as static, self-contained HTML,
**so that** I can drop a believable mockup onto a landing page or share it without any build tooling.

**Priority:** P1  **Size:** S

## Acceptance criteria
- A screen exports as a single self-contained HTML artifact (markup + generated CSS inlined or bundled).
- The HTML renders standalone in a browser with no external framework dependency.
- High-fi exports carry the `theme.yaml`-derived styling; low-fi can export the sketch look.
- `aria-*`/`data-*` attributes are preserved in the output.
- Export scope can be the whole project, a page, or an upverted region.

## Notes / linked README concept
§5 "HTML — static, self-contained" + Key Pages "Export panel" (scope selection).
