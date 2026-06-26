---
id: US-304
title: "Adjust Opposing-View Ratio Globally"
slug: adjust-opposing-view-ratio-globally
personas: [P-005]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, ratio, settings, global]
---

# US-304: Adjust Opposing-View Ratio Globally

## User Story

**As a** debate seeker
**I want to** set a global ratio that controls what share of my feed is opposing-view content
**So that** I can tune the experience to my appetite for exposure to different perspectives

## Acceptance Criteria

- **Given** I open Feed Settings
  **When** I adjust the Opposing-Views ratio slider
  **Then** the slider moves within a bounded range (system minimum to system maximum) and my feed reflects the new ratio within one refresh

- **Given** I set the ratio to the system minimum
  **When** I view my feed
  **Then** opposing-view posts are reduced but not fully eliminated (the system minimum is above zero)

## Notes
Exact bounds (e.g. 5%–30%) are defined by product; this story only specifies the bounded-slider UX and persistence.
