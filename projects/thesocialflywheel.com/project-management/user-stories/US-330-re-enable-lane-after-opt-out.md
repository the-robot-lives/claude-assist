---
id: US-330
title: "Re-Enable Opposing-View Lane After Opting Out"
slug: re-enable-lane-after-opt-out
personas: [P-001]
epic: "Opposing-Views Lane"
priority: should-have
complexity: low
tags: [opposing-views, opt-out, re-enable, settings]
---

# US-330: Re-Enable Opposing-View Lane After Opting Out

## User Story

**As a** bridge-builder
**I want to** re-enable the Opposing-Views Lane after previously opting out
**So that** I can return to the experience when I feel ready without losing my exclusion preferences

## Acceptance Criteria

- **Given** I previously opted out of the lane
  **When** I toggle "Opposing-Views Lane" back to on in Feed Settings
  **Then** the lane reappears immediately and my saved exclusion list is restored

- **Given** the lane is re-enabled
  **When** I view it for the first time after re-enabling
  **Then** the civility framing banner appears again as if first entering the lane

## Notes
Re-enabling must not reset exclusions, saved posts, or ratio settings the user configured before opting out.
