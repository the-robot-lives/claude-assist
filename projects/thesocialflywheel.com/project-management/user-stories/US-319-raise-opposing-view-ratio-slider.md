---
id: US-319
title: "Raise the Opposing-View Ratio"
slug: raise-opposing-view-ratio-slider
personas: [P-005]
epic: "Opposing-Views Lane"
priority: should-have
complexity: low
tags: [opposing-views, ratio, settings, slider]
---

# US-319: Raise the Opposing-View Ratio

## User Story

**As a** debate seeker
**I want to** increase the proportion of opposing-view content in my lane
**So that** I encounter more diverse perspectives aligned with my higher appetite for debate

## Acceptance Criteria

- **Given** I open Feed Settings and locate the Opposing-Views slider
  **When** I drag it toward the maximum
  **Then** my lane shows more opposing-view posts on the next refresh, up to the system cap

- **Given** I set the slider to the system maximum
  **When** I view my lane
  **Then** opposing-view content does not exceed the system-defined cap fraction of total feed content

## Notes
The system cap exists to ensure the feed never feels overtaken by opposing content regardless of user preference.
