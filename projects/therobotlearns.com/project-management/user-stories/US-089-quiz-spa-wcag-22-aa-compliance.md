---
id: US-089
title: "Quiz SPA meets WCAG 2.2 AA compliance"
slug: quiz-spa-wcag-22-aa-compliance
personas: [P-007]
epic: "Accessibility & i18n"
priority: must-have
complexity: high
tags: [accessibility, wcag, spa]
---

# US-089: Quiz SPA Meets WCAG 2.2 AA Compliance

## User Story

**As a** blind senior developer using a screen reader in the browser
**I want to** use a quiz SPA that conforms to WCAG 2.2 AA
**So that** I can navigate and complete quizzes using only the keyboard and screen reader

## Acceptance Criteria

- **Given** the quiz SPA loads
  **When** navigating via Tab/Shift+Tab
  **Then** focus order follows a logical reading sequence and every interactive element is keyboard-reachable

- **Given** a new question or modal appears
  **When** it is displayed
  **Then** focus moves to it automatically and is appropriately managed (trapped in modals) until dismissed or answered

- **Given** any text and UI element in the SPA
  **When** contrast is measured
  **Then** it meets at least a 4.5:1 ratio for normal text and 3:1 for large text/UI components

- **Given** the OS or browser "prefers-reduced-motion" setting is enabled
  **When** animations or transitions would normally play
  **Then** they are disabled or reduced to the minimum necessary

## Notes
Should be validated with an automated WCAG audit tool plus manual screen-reader testing (e.g., NVDA/VoiceOver) as part of definition of done.
