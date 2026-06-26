---
id: US-961
title: "Channel Moderator Health Dashboard"
slug: channel-moderator-health-dashboard
personas: [P-007]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: high
tags: [analytics, moderation, channel, dashboard]
---

# US-961: Channel Moderator Health Dashboard

## User Story

**As a** Channel Moderator
**I want to** see an overview dashboard showing active member count, post volume, report rate, and an engagement health score for my channel
**So that** I can quickly assess whether the channel is thriving or needs intervention

## Acceptance Criteria

- **Given** I am a moderator of at least one channel
  **When** I open the Channel Health Dashboard
  **Then** I see a summary card per channel with active members (last 30 days), weekly post volume, open report count, and a computed health score (0–100)

- **Given** a channel whose health score drops below 40
  **When** I view the dashboard
  **Then** that channel card is highlighted with a warning indicator and a suggested action

- **Given** a channel with no activity in 30 days
  **When** I view the dashboard
  **Then** it is flagged as "dormant" rather than showing a health score

## Notes
Health score is computed from engagement rate, report rate, member retention, and post frequency. Formula details are shown in a tooltip.
