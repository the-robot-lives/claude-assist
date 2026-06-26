---
id: US-955
title: "View Post Propagation Timeline"
slug: view-post-propagation-timeline
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: medium
tags: [analytics, posts, propagation, timeline]
---

# US-955: View Post Propagation Timeline

## User Story

**As a** Creator
**I want to** see a chronological timeline of when my post reached each degree of the mutuals web
**So that** I can identify when content velocity peaks and drops.

## Acceptance Criteria

- **Given** a published post
  **When** I open the propagation timeline
  **Then** I see a time-series chart with separate lines for 1st, 2nd, 3rd, and 4th degree cumulative reach.

- **Given** a post that went viral at 3rd degree 24 hours after publishing
  **When** viewing the timeline
  **Then** the 3rd-degree line shows a steep rise at the 24-hour mark.

## Notes
Timeline resolution is hourly for the first 72 hours, then daily thereafter.
