# US-11 — Retain the text source after upverting

**As** the frontend engineer (`design-system-frontend-engineer`)
**I want** the original text implementation kept as the source of record even after I upvert,
**so that** the artifact is never thrown away and every stage is an enrichment, not a restart.

**Priority:** P1  **Size:** S

## Acceptance criteria
- After upverting, the original text for the element(s) remains stored and viewable.
- The text form is labeled as the canonical source of record.
- I can inspect the text source alongside its upverted structured form.
- Editing the text source is supported and its relationship to the upverted form is well-defined (e.g. re-derive or flag drift).
- Exports and renders can trace back to the originating text source.

## Notes / linked README concept
§4 "Retains the original text implementation as the source of record" + §The lifecycle "The text source is never thrown away."
