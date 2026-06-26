---
id: US-351
title: "Discovery Items Appear in Feed"
slug: discovery-items-appear-in-feed
personas: [P-006]
epic: "Discovery Engine"
priority: must-have
complexity: medium
tags: [discovery, feed]
---

# US-351: Discovery Items Appear in Feed

## User Story

**As a** Quiet Consumer
**I want to** see discovery items interspersed in my main feed
**So that** I am passively exposed to content adjacent to my interests without having to seek it out

## Acceptance Criteria

- **Given** I am logged in and have an established interest profile
  **When** I scroll my main feed
  **Then** discovery items appear at a configured cadence, visually integrated but identifiable as discovery content

- **Given** discovery items are present in my feed
  **When** the feed loads
  **Then** no more than one discovery item appears per five regular feed items by default

## Notes
Discovery items must not dominate the feed; they supplement the core mutuals content.
