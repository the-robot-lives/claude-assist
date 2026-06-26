---
id: US-889
title: "Session Timeout Warning with Extension Option"
slug: session-timeout-warning
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: medium
tags: [session-timeout, accessibility, wcag-2.2]
---

# US-889: Session Timeout Warning with Extension Option

## User Story

**As a** user who may need extra time to complete actions
**I want to** receive a warning before my session times out with an option to extend it
**So that** I do not lose work due to slow reading or motor limitations

## Acceptance Criteria

- **Given** my session will expire in 2 minutes
  **When** the countdown begins
  **Then** a dialog appears announcing "Your session will expire in 2 minutes. Extend session?" and focus moves to the dialog's primary action button

- **Given** the warning dialog is open
  **When** I press "Extend session"
  **Then** the session is renewed, the dialog closes, and focus returns to the element I was interacting with before the dialog appeared

- **Given** I use a screen reader
  **When** the timeout dialog appears
  **Then** it is announced assertively via `aria-live="assertive"` without waiting for me to tab to it

## Notes
The extension option must be operable by keyboard alone. Per WCAG 2.2.1, users must be given at least 20 seconds to respond to a timeout warning and the ability to turn off or extend the time limit.
