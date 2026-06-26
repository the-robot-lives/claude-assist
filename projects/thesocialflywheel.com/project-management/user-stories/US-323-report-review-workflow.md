---
id: US-323
title: "Moderation Review Workflow for Bad-Faith Report"
slug: report-review-workflow
personas: [P-007]
epic: "Opposing-Views Lane"
priority: should-have
complexity: high
tags: [opposing-views, moderation, report, workflow]
---

# US-323: Moderation Review Workflow for Bad-Faith Report

## User Story

**As a** channel moderator
**I want to** have a structured review queue for opposing-view bad-faith reports
**So that** I can efficiently evaluate reported posts and take consistent enforcement actions

## Acceptance Criteria

- **Given** a post has been reported as bad-faith opposing view
  **When** it enters the moderation queue
  **Then** the queue entry includes: the post, the "opposing view on [interest]" context, reporter notes, and past enforcement history for the author

- **Given** I review the report and decide to remove the post from the lane
  **When** I action the removal
  **Then** the post is removed from all users' Opposing-Views Lanes and the reporter receives a notification

## Notes
The moderation queue for opposing-view reports should be visually distinct to help moderators understand the dual-context of the post (the opposing-view role vs general community standards).
