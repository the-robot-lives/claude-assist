---
id: US-026
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Search a class by name and jump to it"
epic: "Search & filter"
priority: P0
segment: primary
tags: [search, jump, name, scoping]
---

# US-026 — Search a class by name and jump to it

**As** Marcus, the newly-onboarding engineer,
**I want** search for a class by name and jump straight to it,
**so that** I can scope a ticket to the right code without ctrl-clicking through files.

## Acceptance criteria
- [ ] A search field matches class/type names with incremental type-ahead results
- [ ] Selecting a result focuses the node and reveals its containment path
- [ ] Recent searches are remembered within a session
- [ ] A query with no match shows a clear 'no results' state, not a silent jump to nowhere

## Notes
Serves Marcus's ticket-scoping scenario (P-002 scenario 2) and goal 2 (find where a feature lives).
