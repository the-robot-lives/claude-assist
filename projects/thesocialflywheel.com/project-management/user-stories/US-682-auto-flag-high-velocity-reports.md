---
id: US-682
title: "Auto-Flag High-Velocity Reports"
slug: auto-flag-high-velocity-reports
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: medium
tags: [auto-moderation, velocity, brigading]
---

# US-682: Auto-Flag High-Velocity Reports

## User Story

**As a** channel moderator
**I want to** have posts that accumulate many reports very quickly automatically surfaced and hidden
**So that** viral harmful content is contained before it spreads while I am offline

## Acceptance Criteria

- **Given** a post receives more than 20 unique-user reports within one hour
  **When** the threshold is crossed
  **Then** the post is auto-hidden, moved to the top of the mod queue marked "High Velocity — Urgent", and I receive a push notification even if I have normal notifications muted

- **Given** a high-velocity flag is applied
  **When** I open the report card
  **Then** I see a velocity graph showing report rate over the past hour alongside the usual report details

- **Given** I dismiss all reports after review (content did not violate rules)
  **When** I confirm the dismissal
  **Then** the post is restored with its original timestamp and the high-velocity flag is cleared

## Notes
The 20-report / 1-hour threshold should be configurable per channel to account for large vs small communities.
