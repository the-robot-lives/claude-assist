---
id: US-911
title: "Interaction to Next Paint Under 200 ms"
slug: inp-responsiveness
personas: [P-008]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: high
tags: [inp, core-web-vitals, responsiveness, accessibility]
---

# US-911: Interaction to Next Paint Under 200 ms

## User Story

**As an** accessibility-first user with motor difficulties who relies on precise tap timing
**I want to** see a visual response to every button tap within 200 milliseconds
**So that** I can trust that my interaction was registered without tapping again

## Acceptance Criteria

- **Given** I tap any interactive element (button, link, toggle)
  **When** the tap is registered
  **Then** a visual state change (ripple, highlight, or state update) appears within 200 ms (INP p75 target)

- **Given** a heavyweight computation is triggered by a tap
  **When** the tap occurs
  **Then** the visual acknowledgment still renders within 200 ms even if the full computation takes longer

## Notes
Yield to the main thread via `scheduler.yield()` or `setTimeout(0)` after immediate visual update. Measure INP using web-vitals library in production.
