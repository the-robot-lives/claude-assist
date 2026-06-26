---
id: US-776
title: "Enable Screen Reader Hints"
slug: enable-screen-reader-hints
personas: [P-008]
epic: "Settings & Preferences"
priority: should-have
complexity: medium
tags: [accessibility, screen-reader, aria, a11y]
---

# US-776: Enable Screen Reader Hints

## User Story

**As a** accessibility-first user
**I want to** have the app surface enhanced screen reader hints and descriptions on key interactive elements
**So that** I can navigate Flywheel Social effectively with a screen reader

## Acceptance Criteria

- **Given** I enable "Enhanced Screen Reader Hints" in Accessibility Settings
  **When** I focus on a post card with a screen reader active
  **Then** the reader announces the author handle, degree of connection, channel name, post excerpt, and available actions.

- **Given** Enhanced Screen Reader Hints is on
  **When** I focus on the opposing-view ratio slider
  **Then** the reader announces the current value as a percentage and describes the min/max range.

## Notes
This preference augments (not replaces) native ARIA markup; it adds context-rich announcements for Flywheel-specific concepts like connection degree and lane type.
