---
id: US-356
title: "Discovery Volume Slider"
slug: discovery-volume-slider
personas: [P-006]
epic: "Discovery Engine"
priority: should-have
complexity: low
tags: [discovery, volume, settings]
---

# US-356: Discovery Volume Slider

## User Story

**As a** Quiet Consumer
**I want to** adjust a slider that controls how many discovery items appear in my feed
**So that** I can tune the density of discovery content to match my current appetite

## Acceptance Criteria

- **Given** I am in my Discovery Settings page
  **When** I move the volume slider
  **Then** the ratio of discovery items in my feed updates immediately on next load (range: 0 – 1 per 3 regular items)

- **Given** I set the slider to zero
  **When** my feed loads
  **Then** no discovery items appear but the setting is saved for future adjustment

## Notes
Volume of zero is distinct from Pause Discovery; zero simply sets ratio to 0 while keeping the engine active.
