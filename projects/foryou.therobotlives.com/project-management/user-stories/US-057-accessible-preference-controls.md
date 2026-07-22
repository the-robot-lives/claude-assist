---
id: US-057
title: "Use accessible preference controls"
slug: accessible-preference-controls
personas: [P-007]
epic: "Contact Preferences"
priority: should-have
complexity: medium
tags: [preferences, accessibility, a11y, wcag]
---

# US-057: Use accessible preference controls

## User Story

**As a** screen-reader user
**I want to** operate all preference controls by keyboard with announced state
**So that** I can manage how I'm contacted without barriers

## Acceptance Criteria

- **Given** the preference controls
  **When** I navigate by keyboard
  **Then** every control is reachable, labeled, and operable
- **Given** I change a preference
  **When** the change applies
  **Then** the new state is announced to assistive technology
- **Given** an error saving preferences
  **When** it occurs
  **Then** it is announced and not conveyed by color alone

## Notes
WCAG 2.1 AA across frequency, channels, periods, and pause controls.
