---
id: US-008
title: "Monitor live robot feed and blocked items"
slug: live-feed
personas: [P-002, P-001]
epic: "Operations Visibility"
priority: should-have
complexity: medium
tags: [dashboard, realtime, observability]
---

# US-008: Monitor live robot feed and blocked items

## User Story

**As an** operations manager  
**I want to** see live robot statuses and blocked work  
**So that** I can intervene before SLAs are missed.

## Acceptance Criteria

- **Given** the dashboard is open, **When** a robot status changes, **Then** I see the update in less than 5 seconds.
- **Given** blocking occurs, **When** I open the event, **Then** I can open the source issue and next required action.

