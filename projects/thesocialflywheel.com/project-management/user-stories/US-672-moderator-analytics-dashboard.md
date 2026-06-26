---
id: US-672
title: "Moderator Analytics Dashboard"
slug: moderator-analytics-dashboard
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: medium
tags: [moderation, analytics]
---

# US-672: Moderator Analytics Dashboard

## User Story

**As a** channel moderator
**I want to** view an analytics dashboard for my channel's moderation activity
**So that** I can identify trends, measure response times, and improve our moderation practice

## Acceptance Criteria

- **Given** I open the Moderation Analytics tab
  **When** the dashboard loads
  **Then** I see cards for: total reports in period, median time-to-resolution, breakdown of actions taken (remove / warn / timeout / ban / dismissed), and appeal overturn rate

- **Given** I select a time window (7 days, 30 days, 90 days, custom)
  **When** the filter is applied
  **Then** all dashboard metrics update to reflect only that period without a full page reload

- **Given** report volume spikes significantly week-over-week
  **When** the dashboard renders
  **Then** a highlighted annotation flags the spike so I can investigate

## Notes
Analytics data should be aggregated and anonymised; individual reporter identities must not appear in any chart or export.
