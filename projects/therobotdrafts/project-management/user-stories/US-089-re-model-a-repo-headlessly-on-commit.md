---
id: US-089
persona: P-008
persona_slug: trd-automation-agent
title: "Re-model a repo headlessly on commit"
epic: "Automation / headless / API"
priority: P0
segment: edge-case
tags: [headless, cli, ci, re-model]
---

# US-089 — Re-model a repo headlessly on commit

**As** ARIA, the automation agent,
**I want** import and re-model a repository headlessly via CLI/API on every commit,
**so that** the model stays continuously in sync with code without a human clicking.

## Acceptance criteria
- [ ] A headless command ingests a repo path and writes/updates the model with no GUI
- [ ] The command is idempotent and incremental: unchanged files don't force a full rebuild
- [ ] It runs in CI without a display/headset and exits with a status code reflecting success/failure
- [ ] A parse/IO failure produces a non-zero exit and a machine-readable error, never a silent partial success

## Notes
Serves ARIA's CI-re-model scenario (P-008 scenario 1) and goal 1; counters frustration 1 (GUI-only paths).
