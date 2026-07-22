---
id: US-099
title: "TalkBack/screen-reader support on sell screen"
slug: "talkback-screen-reader-sell-screen"
personas: [P-003, P-001]
epic: "Accessibility & i18n"
priority: "should-have"
complexity: "L"
tags: [accessibility, a11y, sell-screen]
---

# US-099: TalkBack/screen-reader support on sell screen

## User Story

**As a** cashier (P-003) with low vision,
**I want** the sell screen to work correctly with Android TalkBack,
**So that** I can operate the register independently without needing sighted assistance.

## Acceptance Criteria

- [ ] Given TalkBack is enabled on the device, when the user navigates the sell screen, then every interactive element (item buttons, quantity steppers, payment buttons) has a meaningful spoken label in the active app language (Khmer or English per US-084).
- [ ] Given a sale total or change-due amount updates, when TalkBack is active, then the change is announced via an accessibility live region so the user doesn't have to manually re-navigate to hear it.
- [ ] Given the user completes checkout using only TalkBack navigation and gestures, when they reach the confirmation step, then no action on the critical sale path requires a sighted-only gesture (e.g., a drag-only control with no accessible alternative).

## Notes

Should-have — important for inclusive design but scoped to the sell screen first per the README's core-register focus; other screens can follow in later iterations. Khmer-language screen reader support depends on TalkBack's Khmer TTS availability on target devices, which should be verified early. Depends on US-084.
