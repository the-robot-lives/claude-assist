---
id: US-554
title: "See Read-Only State on Opposing-Views Posts"
slug: read-only-opposing-views
personas: [P-005, P-006]
epic: "Reactions & Engagement"
priority: must-have
complexity: low
tags: [opposing-views, read-only, lane]
---

# US-554: See Read-Only State on Opposing-Views Posts

## User Story

**As a** Debate Seeker
**I want to** clearly see that Opposing-Views posts are read-only
**So that** I understand why reaction and reply controls are disabled

## Acceptance Criteria

- **Given** I am viewing the Opposing-Views lane
  **When** I look at any post
  **Then** reaction and reply buttons are visually disabled and labelled "Read only in this lane"

- **Given** I attempt to tap a disabled reaction button
  **When** the action is blocked
  **Then** a tooltip explains the read-only rule without navigating me away from the post

## Notes
Do not hide the controls; disable and explain to avoid user confusion and build trust in the lane design.
