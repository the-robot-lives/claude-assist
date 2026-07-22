---
id: US-080
title: "Demo mode with sample data"
slug: "demo-mode"
personas: [P-007, P-001]
epic: "Onboarding & Setup"
priority: "could-have"
complexity: "S"
tags: [onboarding, demo]
---

# US-080: Demo mode with sample data

## User Story

**As an** NGO program manager (P-007),
**I want to** let a prospective merchant try the app with sample data before committing their real inventory,
**So that** they can evaluate the product risk-free during a training session.

## Acceptance Criteria

- [ ] Given a user on the signup screen, when they tap "Try demo," then they enter a sandboxed store pre-loaded with sample items, sample sales history, and a sample cash drawer — no phone number required.
- [ ] Given a user is in demo mode, when they perform any sale or inventory action, then changes are stored locally only and never synced to a real backend tenant.
- [ ] Given a user in demo mode, when they tap "Sign up for real," then they are routed to the real signup flow (US-076) with the demo data discarded.

## Notes

Useful for NGO-led training sessions (P-007) and market research/demos. Not a v1 launch blocker.
