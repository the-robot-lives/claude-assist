---
id: US-053
title: "Set quiet periods for contact"
slug: set-quiet-periods
personas: [P-001]
epic: "Contact Preferences"
priority: should-have
complexity: medium
tags: [preferences, periods, quiet-hours, timezone]
---

# US-053: Set quiet periods for contact

## User Story

**As a** subscriber
**I want to** define quiet hours/windows when I should not be contacted
**So that** messages arrive at acceptable times

## Acceptance Criteria

- **Given** I manage preferences
  **When** I set a quiet period with a timezone
  **Then** the window and timezone are stored on my preferences
- **Given** a quiet period is set
  **When** future delivery is scheduled
  **Then** sends are deferred outside the quiet window
- **Given** no timezone is provided
  **When** I set a period
  **Then** a sensible default timezone is used and shown to me

## Notes
Timezone-aware; enforced when delivery is implemented.
