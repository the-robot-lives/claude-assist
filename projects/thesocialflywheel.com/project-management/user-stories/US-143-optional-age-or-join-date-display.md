---
id: US-143
title: "Optional age or join-date display"
slug: optional-age-or-join-date-display
personas: [P-006]
epic: "Profile & Identity"
priority: could-have
complexity: low
tags: [profile, identity, privacy]
---

# US-143: Optional Age or Join-Date Display

## User Story

**As a** quiet consumer
**I want to** choose whether my age or join date shows on my profile
**So that** I can share just enough context without exposing details I would rather keep private

## Acceptance Criteria

- **Given** I am editing my profile
  **When** I toggle "show join date" or "show age"
  **Then** the chosen fields appear or disappear on my public profile accordingly

- **Given** both display toggles are off
  **When** another member views my profile
  **Then** neither my age nor my join date is shown

## Notes
Defaults to hidden to favor privacy for low-engagement members.
