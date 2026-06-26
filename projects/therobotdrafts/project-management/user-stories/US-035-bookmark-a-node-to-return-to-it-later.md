---
id: US-035
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Bookmark a node to return to it later"
epic: "Persistence & document management"
priority: P2
segment: primary
tags: [bookmark, navigation, persistence, return]
---

# US-035 — Bookmark a node to return to it later

**As** Marcus, the newly-onboarding engineer,
**I want** bookmark a node so I can return to it across sessions,
**so that** I can keep my place on the parts of the system I'm responsible for.

## Acceptance criteria
- [ ] Bookmarking a node adds it to a bookmarks list with its qualified name
- [ ] Selecting a bookmark focuses and frames that node
- [ ] Bookmarks persist across app restarts and survive re-ingest where the node still exists
- [ ] A bookmark to a removed node is flagged as stale rather than silently jumping nowhere

## Notes
Supports spatial memory for a returning onboarder; lighter-weight than Dana's saved views (US-015).
