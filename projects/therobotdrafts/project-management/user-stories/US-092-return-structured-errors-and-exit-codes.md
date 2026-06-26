---
id: US-092
persona: P-008
persona_slug: trd-automation-agent
title: "Return structured errors and exit codes"
epic: "Automation / headless / API"
priority: P1
segment: edge-case
tags: [errors, exit-codes, machine-readable, contract]
---

# US-092 — Return structured errors and exit codes

**As** ARIA, the automation agent,
**I want** get machine-readable errors and meaningful exit codes from every operation,
**so that** a pipeline can detect and react to failures instead of guessing.

## Acceptance criteria
- [ ] Every headless operation returns a structured error object (code, message, context) on failure
- [ ] Exit codes distinguish success, user/config error, and internal failure
- [ ] Errors are emitted to a stable stream (not just a transient UI flash)
- [ ] Partial successes are reported explicitly with per-item status rather than a single ambiguous result

## Notes
Counters ARIA's frustration 2 (silent/ephemeral errors); the build's one-shot hint flash (UX-review P1-2) is unusable for CI.
