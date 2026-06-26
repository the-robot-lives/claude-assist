---
id: US-029
title: "Screen-Reader-Accessible Onboarding"
slug: screen-reader-accessible-onboarding
personas: [P-008, P-004]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [accessibility, screen-reader, a11y, onboarding]
---

# US-029: Screen-Reader-Accessible Onboarding

## User Story

**As a** user who relies on a screen reader
**I want to** every onboarding screen to be fully navigable by voice
**So that** I can set up my account without sighted assistance

## Acceptance Criteria

- **Given** I navigate onboarding with VoiceOver (iOS) or TalkBack (Android)
  **When** I reach each screen
  **Then** all interactive elements have descriptive labels and focus order is logical top-to-bottom.

- **Given** an animation plays during onboarding
  **When** my screen reader is active or "reduce motion" is on
  **Then** the animation is replaced with a static equivalent that conveys the same information.

## Notes
WCAG 2.1 AA minimum. Run automated a11y audit plus manual VoiceOver/TalkBack pass before each release. Swipe gesture tutorial needs an alternative non-gesture path.
