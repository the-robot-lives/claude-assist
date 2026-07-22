---
id: US-069
title: "Use an accessible preference-center dashboard"
slug: accessible-preference-center
personas: [P-007]
epic: "Preference Center"
priority: should-have
complexity: medium
tags: [preference-center, accessibility, a11y, wcag]
---

# US-069: Use an accessible preference-center dashboard

## User Story

**As a** screen-reader user
**I want to** operate the whole preference center by keyboard with announced changes
**So that** I can manage my subscriptions and preferences independently

## Acceptance Criteria

- **Given** the dashboard
  **When** I navigate by keyboard
  **Then** all groups, subscriptions, and actions are reachable and labeled
- **Given** I unsubscribe or change a preference
  **When** the action completes
  **Then** the result is announced via a live region
- **Given** the dashboard loads on a slow connection
  **When** content arrives
  **Then** it renders progressively and remains usable

## Notes
WCAG 2.1 AA; low-bandwidth friendly.
