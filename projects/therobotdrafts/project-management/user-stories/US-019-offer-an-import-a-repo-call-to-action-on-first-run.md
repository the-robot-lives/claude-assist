---
id: US-019
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Offer an 'Import a repo' call-to-action on first run"
epic: "Onboarding & first-run"
priority: P0
segment: primary
tags: [first-run, import, cta, onboarding]
---

# US-019 — Offer an 'Import a repo' call-to-action on first run

**As** Marcus, the newly-onboarding engineer,
**I want** be offered a prominent 'Import a repo' action the first time I open the app,
**so that** the product's fly-through wow moment is the first thing I do, not a context-menu hunt.

## Acceptance criteria
- [ ] On first launch with no document, a center-screen 'Import a repo' CTA is the primary action
- [ ] Choosing it opens a repo picker and runs ingestion into the bubble view
- [ ] The CTA also exposes 'open an example model' for users without a repo handy
- [ ] Dismissing the CTA leaves the empty-state prompt visible so the next step is still discoverable

## Notes
Implements UX-review recommendation E18; the import->model->fly-through path is built for Marcus (P-002 relationship).
