---
id: US-033
persona: P-002
persona_slug: trd-onboarding-engineer
title: "Open the code behind a bubble in my editor"
epic: "Code round-trip & LLM codegen"
priority: P1
segment: primary
tags: [go-to-code, editor, round-trip, navigation]
---

# US-033 — Open the code behind a bubble in my editor

**As** Marcus, the newly-onboarding engineer,
**I want** jump from a bubble to the exact source location it was derived from,
**so that** I can read the real code as soon as the model points me at it.

## Acceptance criteria
- [ ] A 'go to code' action on a node opens the originating file at the right line in the editor/viewer
- [ ] The action is available on classes, methods, and fields that have a source origin
- [ ] Nodes recovered without a precise source location (e.g. decompiled) indicate that instead of opening a wrong file
- [ ] The mapping stays correct after an incremental re-ingest

## Notes
Marcus is a heavy go-to-definition user (P-002 behaviors); bridges model back to code.
