---
id: US-674
title: "Accessible Moderation Tools"
slug: accessible-moderation-tools
personas: [P-007]
epic: "Moderation & Reporting"
priority: must-have
complexity: medium
tags: [accessibility, moderation, a11y]
---

# US-674: Accessible Moderation Tools

## User Story

**As a** channel moderator who relies on a screen reader and keyboard navigation
**I want to** perform every moderation action without requiring a mouse
**So that** my disability does not prevent me from running my channel effectively

## Acceptance Criteria

- **Given** I am navigating the report queue with a keyboard
  **When** I tab through report cards
  **Then** focus is visible, every interactive element (claim, remove, warn, timeout, ban, dismiss) is reachable by Tab/Enter, and no action requires drag-and-drop

- **Given** I use a screen reader
  **When** a new report arrives and the queue updates
  **Then** an ARIA live region announces the new report count without disrupting my current focus

- **Given** I open a modal action dialog (e.g. "Timeout User")
  **When** the dialog appears
  **Then** focus moves into the dialog, is trapped within it until I confirm or cancel, and returns to the triggering element on close (WCAG 2.1 AA Focus Management)

## Notes
All moderation surfaces should be audited against WCAG 2.1 AA as part of acceptance; colour alone must never convey report severity.
