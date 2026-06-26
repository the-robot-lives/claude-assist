---
id: US-696
title: "Channel Health Score"
slug: channel-health-score
personas: [P-007]
epic: "Moderation & Reporting"
priority: could-have
complexity: medium
tags: [moderation, analytics, channel-health]
---

# US-696: Channel Health Score

## User Story

**As a** channel owner
**I want to** see a computed health score for my channel's moderation quality
**So that** I can identify declining trends early and decide whether to recruit more mods or adjust rules

## Acceptance Criteria

- **Given** I open Channel Settings > Health
  **When** the page loads
  **Then** I see a 0–100 health score derived from: report rate per 1k posts (lower is better), median resolution time (faster is better), repeat-offender rate (lower is better), and appeal overturn rate (lower is better)

- **Given** the health score drops below 60
  **When** the score renders
  **Then** a callout appears recommending specific actions (e.g. "Your resolution time is above average — consider adding a moderator")

- **Given** I hover over the score
  **When** the tooltip appears
  **Then** I see each contributing factor's individual sub-score and its weight in the overall formula

## Notes
The health score formula should be published in the platform help centre so owners understand how to improve it without gaming it.
