---
id: US-045
persona: P-003
persona_slug: trd-tech-lead
title: "Anchor comment threads to elements for async review"
epic: "Collaboration / sharing / annotation"
priority: P1
segment: secondary
tags: [comments, threads, async, review]
---

# US-045 — Anchor comment threads to elements for async review

**As** Priya, the tech lead,
**I want** leave threaded comments anchored to model elements that teammates can reply to,
**so that** we can run an async design review without a live meeting.

## Acceptance criteria
- [ ] A comment thread can be attached to any element and shows author, time, and replies
- [ ] Unresolved threads are indicated on the element; resolving a thread hides it from the default view
- [ ] Comments persist with the shared model and are visible to anyone with access
- [ ] A thread on a removed element is preserved as orphaned with context rather than lost

## Notes
Deepens collaboration beyond one-shot annotations (US-038); supports async review for a distributed team.
