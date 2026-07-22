---
id: US-078
title: "First-run guided tutorial"
slug: "first-run-tutorial"
personas: [P-001]
epic: "Onboarding & Setup"
priority: "must-have"
complexity: "M"
tags: [onboarding, tutorial, ux]
---

# US-078: First-run guided tutorial

## User Story

**As a** first-time smartphone user (P-001),
**I want to** see an interactive walkthrough of the sell screen the first time I use it,
**So that** I can start ringing up sales without reading a manual.

## Acceptance Criteria

- [ ] Given a user completes store setup for the first time, when they land on the sell screen, then an overlay walkthrough highlights the key actions (add item, take payment, print/skip receipt) in sequence.
- [ ] Given the walkthrough is active, when the user taps "skip," then the tutorial closes and does not reappear automatically.
- [ ] Given a user completes the walkthrough or skips it, when they return to the sell screen later, then a "help" icon remains available to replay the tutorial on demand.

## Notes

Tutorial content must be Khmer-first with English toggle (see US-084). No manual should ever be required — this directly satisfies product principle 1 ("if it needs a manual, it's wrong"). Depends on US-077.
