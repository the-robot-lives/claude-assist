---
id: US-636
title: "Keyboard-Accessible Block Flow"
slug: keyboard-accessible-block-flow
personas: [P-008]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, accessibility, blocking]
---

# US-636: Keyboard-Accessible Block Flow

## User Story

**As an** accessibility-first user
**I want to** complete the entire block flow using only keyboard navigation
**So that** I can protect myself without relying on a pointer device

## Acceptance Criteria

- **Given** I am viewing a user's profile
  **When** I open the options menu with the keyboard and navigate to "Block"
  **Then** focus moves predictably to the block confirmation dialog

- **Given** the block confirmation dialog is open
  **When** I press Tab to navigate cascade options and Enter to confirm
  **Then** the block is applied and focus returns to a logical point in the calling page

## Notes
WCAG 2.1 AA compliance required; focus trap inside the modal; Escape key cancels.
