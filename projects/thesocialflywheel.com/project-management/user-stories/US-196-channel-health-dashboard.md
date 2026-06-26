---
id: US-196
title: "Channel Health Dashboard for Moderators"
slug: channel-health-dashboard
personas: [P-007]
epic: "Interest Channels"
priority: could-have
complexity: high
tags: [channels, moderation, analytics, health, dashboard]
---

# US-196: Channel Health Dashboard for Moderators

## User Story

**As a** Channel Moderator
**I want to** view a health dashboard showing member growth, post activity, lane distribution, and moderation actions over time
**So that** I can make informed decisions about community direction, rule enforcement, and feature usage

## Acceptance Criteria

- **Given** I open the channel's moderation panel
  **When** I tap "Channel Health"
  **Then** I see a summary view with: 7-day member growth delta, total posts per lane (Mutuals / Swipe / Opposing), recent moderation actions count, and the current opposing-view ratio

- **Given** I select a 30-day time range
  **When** the dashboard refreshes
  **Then** all metrics update to reflect the selected window, with trend arrows indicating growth or decline vs the previous equivalent period

## Notes
Dashboard data should be available only to moderators and owner. It does not expose individual user behavior — all metrics are aggregated. Data refresh cadence: daily minimum, near-real-time is a stretch goal.
