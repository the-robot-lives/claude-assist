---
id: US-015
persona: P-001
persona_slug: trd-systems-architect
title: "Save named architecture views and bookmarks"
epic: "Persistence & document management"
priority: P1
segment: primary
tags: [bookmarks, views, persistence, saved-state]
---

# US-015 — Save named architecture views and bookmarks

**As** Dana, the Systems Architect,
**I want** save the current framing, filters, and selection as a named view I can return to,
**so that** I can keep a set of authoritative views for recurring reviews.

## Acceptance criteria
- [ ] Saving a view captures camera framing, active filters/overlays, and selection under a name
- [ ] A views list lets me reopen any saved view, restoring its exact framing and filters
- [ ] Saved views survive re-ingest and re-resolve to the same elements where they still exist
- [ ] A view referencing deleted elements opens to the nearest valid framing and notes what is missing

## Notes
Counters UX-review P1-1 (no document/view persistence) at the architect's recurring-review scale.
