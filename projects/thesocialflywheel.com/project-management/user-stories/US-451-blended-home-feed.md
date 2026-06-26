---
id: US-451
title: "View blended home feed"
slug: blended-home-feed
personas: [P-006]
epic: "Feed & Ranking"
priority: must-have
complexity: high
tags: [feed, home, blend, lanes]
---

# US-451: View Blended Home Feed

## User Story

**As a** quiet consumer (P-006)
**I want to** see a single home feed that blends posts from my mutuals, interest-filtered posts from 2nd–4th degree connections, Opposing-Views, and Discovery items
**So that** I can passively browse relevant content without switching between multiple sections

## Acceptance Criteria

- **Given** I have at least one mutual and am subscribed to at least one channel
  **When** I open the home feed
  **Then** I see a ranked list mixing all four lane types in their configured ratios

- **Given** the feed is loaded
  **When** I scroll through it
  **Then** mutual posts appear at their native weight, 2nd-degree posts are discounted relative to 1st-degree, 3rd/4th-degree discounted further, with Opposing-Views and Discovery slots interspersed at fixed ratios

## Notes
The blend ratio is user-configurable via the lane mix controls (see US-461).
