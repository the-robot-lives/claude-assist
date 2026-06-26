---
id: US-093
persona: P-008
persona_slug: trd-automation-agent
title: "Cancel and time out long operations"
epic: "Automation / headless / API"
priority: P1
segment: edge-case
tags: [cancellation, timeout, long-running, contract]
---

# US-093 — Cancel and time out long operations

**As** ARIA, the automation agent,
**I want** set timeouts and cancel long-running operations like folder import or codegen,
**so that** a stuck operation can't hang my pipeline indefinitely.

## Acceptance criteria
- [ ] Every long operation accepts a timeout and aborts cleanly when exceeded
- [ ] A cancellation request stops the operation and leaves the model in a consistent state
- [ ] Progress is reported in a machine-readable form during the operation
- [ ] A timeout/cancel yields a distinct exit code and structured reason, not a generic failure

## Notes
Counters ARIA's frustration 3 (long ops with no cancel/timeout); UX-review P1-2 notes no cancel exists.
