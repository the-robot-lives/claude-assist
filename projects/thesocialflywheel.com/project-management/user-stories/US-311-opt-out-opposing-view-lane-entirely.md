---
id: US-311
title: "Opt Out of the Opposing-View Lane Entirely"
slug: opt-out-opposing-view-lane-entirely
personas: [P-004]
epic: "Opposing-Views Lane"
priority: must-have
complexity: low
tags: [opposing-views, opt-out, settings, safety]
---

# US-311: Opt Out of the Opposing-View Lane Entirely

## User Story

**As a** cautious newcomer
**I want to** disable the Opposing-Views Lane completely with a single toggle
**So that** I am not shown any opposing-view content if I decide the feature is not right for me

## Acceptance Criteria

- **Given** I open Feed Settings
  **When** I toggle "Opposing-Views Lane" to off
  **Then** the lane disappears immediately and no opposing-view posts appear anywhere in my feed

- **Given** I have opted out
  **When** I return to Feed Settings
  **Then** the toggle clearly shows the lane is off and provides a brief description of what I am missing

## Notes
Opt-out must be reversible at any time without data loss. Previous exclusion list settings are preserved and restored if the user re-enables.
