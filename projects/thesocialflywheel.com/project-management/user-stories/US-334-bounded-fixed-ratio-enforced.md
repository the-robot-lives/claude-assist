---
id: US-334
title: "System Enforces Bounded Fixed Ratio"
slug: bounded-fixed-ratio-enforced
personas: [P-005]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, ratio, system, enforcement]
---

# US-334: System Enforces Bounded Fixed Ratio

## User Story

**As a** debate seeker
**I want to** trust that the system enforces hard upper and lower bounds on the opposing-view ratio
**So that** my feed cannot be accidentally or deliberately overwhelmed by opposing content

## Acceptance Criteria

- **Given** the system calculates how many opposing-view posts to include
  **When** any user's ratio preference is evaluated
  **Then** the result is clamped to the system-defined min/max regardless of the user's slider position

- **Given** a platform administrator changes the system-wide bounds
  **When** the change is applied
  **Then** all users whose stored preferences fall outside the new bounds are automatically adjusted to the nearest bound

## Notes
System bounds are a platform configuration, not a user preference. Changes to bounds require a platform-level configuration deploy.
