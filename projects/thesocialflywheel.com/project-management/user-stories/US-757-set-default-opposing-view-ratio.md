---
id: US-757
title: "Set Default Opposing-View Ratio"
slug: set-default-opposing-view-ratio
personas: [P-005]
epic: "Settings & Preferences"
priority: must-have
complexity: medium
tags: [content-preferences, opposing-views, ratio, debate]
---

# US-757: Set Default Opposing-View Ratio

## User Story

**As a** debate seeker
**I want to** set the default ratio of opposing-view posts in my feed
**So that** I can calibrate how much challenging content I encounter per session.

## Acceptance Criteria

- **Given** I am on Content Preferences
  **When** I drag the opposing-view slider to 40%
  **Then** 40% of posts in my Opposing-Views lane come from accounts whose stated views diverge from mine.

- **Given** I set the ratio
  **When** I navigate away and return to settings
  **Then** the saved value persists and is reflected in my feed immediately on next refresh.

## Notes
The slider range is 0–100% with a default of 20%. Setting to 0% effectively disables the Opposing-Views lane.
