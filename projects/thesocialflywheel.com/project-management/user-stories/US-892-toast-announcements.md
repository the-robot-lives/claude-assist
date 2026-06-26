---
id: US-892
title: "Accessible Toast and Notification Announcements"
slug: toast-announcements
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [live-regions, notifications, screen-reader, wcag-2.2]
---

# US-892: Accessible Toast and Notification Announcements

## User Story

**As a** screen-reader user
**I want to** have toast notifications announced by my screen reader
**So that** I do not miss transient status messages that appear and disappear visually

## Acceptance Criteria

- **Given** a success toast fires (e.g., "Post published!")
  **When** it appears
  **Then** a polite live region (`aria-live="polite"`) announces the message text without interrupting in-progress speech

- **Given** an error toast fires
  **When** it appears
  **Then** an assertive live region (`aria-live="assertive"`) announces the error immediately, interrupting lower-priority speech

- **Given** a dismissible toast has a close button
  **When** the button is focused via keyboard
  **Then** it is reachable via Tab and labelled "Dismiss notification" not just an "×" character

## Notes
Do not use `role="alert"` indiscriminately for all toasts — reserve assertive/alert for errors and confirmations requiring user attention. Informational toasts should use polite mode to avoid interrupting reading flow.
