---
id: US-881
title: "Accessible Inline Error Messages"
slug: accessible-error-messages
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [error-messaging, forms, screen-reader, wcag-2.2]
---

# US-881: Accessible Inline Error Messages

## User Story

**As a** screen-reader user
**I want to** have form errors announced immediately and linked to the offending field
**So that** I know exactly what to fix and where without hunting through the page

## Acceptance Criteria

- **Given** I submit a form with missing required fields
  **When** the error state renders
  **Then** each error message is associated with its field via `aria-describedby` and announced by the screen reader when focus enters the field

- **Given** an error message appears
  **When** screen reader focus is on the field
  **Then** it reads both the field label and the full error text in sequence

- **Given** I correct a field error
  **When** the field validates successfully inline
  **Then** a polite live region announces "[Field name] is now valid"

## Notes
Never rely on color (red border) alone to indicate errors; always include an icon and plain-text message. Error messages must persist until corrected — do not auto-dismiss.
