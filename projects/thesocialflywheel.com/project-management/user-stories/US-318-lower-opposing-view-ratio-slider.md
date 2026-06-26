---
id: US-318
title: "Lower the Opposing-View Ratio"
slug: lower-opposing-view-ratio-slider
personas: [P-004]
epic: "Opposing-Views Lane"
priority: must-have
complexity: low
tags: [opposing-views, ratio, settings, slider]
---

# US-318: Lower the Opposing-View Ratio

## User Story

**As a** cautious newcomer
**I want to** reduce the proportion of opposing-view posts without fully opting out
**So that** I can experiment with a lighter exposure before deciding whether to continue

## Acceptance Criteria

- **Given** I open Feed Settings and locate the Opposing-Views slider
  **When** I drag it toward the minimum
  **Then** my feed immediately shows fewer opposing-view posts on the next refresh

- **Given** I set the slider to the system minimum
  **When** I view my lane
  **Then** at least one opposing-view post still appears per session (minimum is not zero)

## Notes
Minimum floor value is enforced by the system; the user cannot slide below it. Show the numeric percentage next to the slider.
