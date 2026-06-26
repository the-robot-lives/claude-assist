---
id: US-861
title: "Focus Trap in Modal Dialogs"
slug: focus-trap-modal
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: medium
tags: [focus-management, modals, wcag-2.2]
---

# US-861: Focus Trap in Modal Dialogs

## User Story

**As a** keyboard or screen-reader user
**I want to** have focus trapped inside modal dialogs
**So that** I cannot accidentally interact with background content while a modal is open

## Acceptance Criteria

- **Given** a modal opens (report, share, settings)
  **When** I press Tab
  **Then** focus cycles only within the modal

- **Given** a modal is open
  **When** I press Escape
  **Then** the modal closes and focus returns to the element that opened it

- **Given** the modal opens
  **When** it appears
  **Then** focus automatically moves to the modal's heading or first focusable element

## Notes

Implement using aria-modal="true" and the inert attribute on background content. Maintain a focus-return stack so nested modals restore focus correctly through all dismissal levels.
