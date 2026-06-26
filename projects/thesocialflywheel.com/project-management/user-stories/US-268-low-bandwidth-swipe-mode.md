---
id: US-268
title: "Low-Bandwidth Swipe Mode"
slug: low-bandwidth-swipe-mode
personas: [P-004]
epic: "Swipe-to-Match"
priority: should-have
complexity: medium
tags: [low-bandwidth, performance, accessibility, data-saver]
---

# US-268: Low-Bandwidth Swipe Mode

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** use the swipe lane on a slow or metered connection
**So that** I can still discover potential connections without burning through my data

## Acceptance Criteria

- **Given** my device is on a slow connection or I have enabled Data Saver
  **When** the swipe lane loads
  **Then** candidate avatars are replaced with initials placeholders and post previews are text-only

- **Given** low-bandwidth mode is active
  **When** I swipe in any direction
  **Then** the action completes in under 2 seconds with no animation blocking the interaction
