---
id: US-018
title: "Training mode"
slug: "training-mode"
personas: [P-001, P-003]
epic: "Register & Checkout"
priority: "could-have"
complexity: "M"
tags: [training, onboarding]
---

# US-018: Training Mode

## User Story

**As a** market-stall owner (P-001),
**I want to** use a training mode that mimics the real sell screen without touching real inventory or cash records,
**So that** new staff can practice before working live.

## Acceptance Criteria

- [ ] Given training mode is enabled, when a sale is completed, then it is clearly watermarked as a training transaction and excluded from real sales totals, inventory deductions, and audit reports.
- [ ] Given a user is in training mode, when they navigate the app, then every screen shows a persistent visual indicator (banner or badge) that it is not a live register.
- [ ] Given training mode is exited, when the cashier returns to the live register, then no training data has leaked into real cart state or reports.

## Notes

Scripted training scenarios are won't-have-yet; this is a sandboxed toggle only for v1.
