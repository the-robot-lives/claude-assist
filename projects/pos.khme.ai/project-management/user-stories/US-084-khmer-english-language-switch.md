---
id: US-084
title: "Khmer/English language switch"
slug: "khmer-english-language-switch"
personas: [P-001, P-006]
epic: "Settings & Localization"
priority: "must-have"
complexity: "S"
tags: [localization, settings, i18n]
---

# US-084: Khmer/English language switch

## User Story

**As a** Khmer-only market-stall owner (P-001),
**I want to** use the entire app in Khmer by default with an easy toggle to English,
**So that** I can use the register comfortably regardless of which language I'm most fluent in.

## Acceptance Criteria

- [ ] Given a new install with device locale set to Khmer, when the app first launches, then all UI text, including the tutorial and OTP flow, renders in Khmer by default.
- [ ] Given a user opens Settings > Language, when they switch to English (or back to Khmer), then the change applies app-wide immediately without requiring a restart.
- [ ] Given mixed-language content (e.g., a bookkeeper's export), when the language is set to Khmer, then user-facing labels remain Khmer while raw data values (item names entered by the user) are unaffected by the toggle.

## Notes

Khmer-first localization is the core product moat per the README; this story must ship before general availability. Related: US-078 (tutorial), US-099 (TalkBack).
