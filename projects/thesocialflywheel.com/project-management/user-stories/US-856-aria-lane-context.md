---
id: US-856
title: "ARIA Lane Context Announcement"
slug: aria-lane-context
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [screen-reader, aria, lanes, wcag-2.2]
---

# US-856: ARIA Lane Context Announcement

## User Story

**As a** screen-reader user
**I want to** have the active lane announced when I switch lanes
**So that** I always know which feed context I am viewing

## Acceptance Criteria

- **Given** I am on the Mutuals lane
  **When** I switch to Discovery
  **Then** a live region announces "Now viewing Discovery lane"

- **Given** I enter the Opposing-Views lane
  **When** it loads
  **Then** the screen reader announces "Opposing-Views lane: read-only" before the first post

- **Given** the lane tab is focused
  **When** the screen reader reads it
  **Then** it announces the tab label and its selected state via aria-selected

## Notes

Use role="tablist" / role="tab" with aria-selected on the lane switcher component. The live region for lane change announcements should use aria-live="polite" so it does not interrupt an in-progress announcement.
