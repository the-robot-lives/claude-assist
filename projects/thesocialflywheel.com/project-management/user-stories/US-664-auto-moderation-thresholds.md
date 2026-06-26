---
id: US-664
title: "Auto-Moderation Thresholds"
slug: auto-moderation-thresholds
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: medium
tags: [auto-moderation, thresholds]
---

# US-664: Auto-Moderation Thresholds

## User Story

**As a** channel moderator
**I want to** set a report-count threshold that automatically hides a post pending my review
**So that** content that many users find offensive is suppressed quickly even before I check the queue

## Acceptance Criteria

- **Given** I set the channel auto-hide threshold to N reports
  **When** a post accumulates N unique-user reports
  **Then** the post is immediately hidden from all members (except the author and mods) and moved to the top of the mod queue marked "Auto-hidden"

- **Given** a post is auto-hidden
  **When** I review and dismiss the reports
  **Then** the post is restored to the channel feed with no further action

- **Given** I have not configured a threshold
  **When** the channel is created
  **Then** the platform default threshold of 5 reports applies

## Notes
Threshold configuration should surface the current platform default and warn if the mod sets a value above 20 (risks delay for egregious content).
