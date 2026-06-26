---
id: US-884
title: "Button-Based Swipe Alternative"
slug: swipe-button-alternative
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [swipe-alternative, keyboard, accessibility, wcag-2.2]
---

# US-884: Button-Based Swipe Alternative

## User Story

**As a** user who cannot perform touch swipe gestures
**I want to** see clearly labelled Accept and Skip buttons on every swipe card
**So that** I can participate in Swipe-to-Match without relying on gesture input

## Acceptance Criteria

- **Given** the Swipe-to-Match lane is active
  **When** I view a card
  **Then** visible "Accept" and "Skip" buttons are present below the card and reachable by Tab in logical order

- **Given** I activate "Accept" by keyboard or pointer click
  **When** the action fires
  **Then** it is functionally identical to a right-swipe gesture in all respects (match logic, animations, follow-on state)

- **Given** the swipe deck is rendered on any device or input modality
  **When** it loads
  **Then** keyboard/button alternatives are always present — not conditionally hidden based on detected input device

## Notes
Buttons must meet the 44×44 CSS pixel minimum touch-target size per WCAG 2.5.5. Do not use `pointer-events: none` patterns that suppress button rendering for touch users.
