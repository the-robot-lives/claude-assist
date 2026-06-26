---
id: US-413
title: "Opt post out of opposing-view distribution"
slug: opt-out-opposing-view
personas: [P-009]
epic: "Posting & Content Creation"
priority: should-have
complexity: low
tags: [opposing-views, privacy, audience-control]
---

# US-413: Opt Post Out of Opposing-View Distribution

## User Story

**As a** Creator
**I want to** explicitly exclude my post from the Opposing-Views lane
**So that** my content only reaches my intended mutual-graph audience

## Acceptance Criteria

- **Given** I am composing a post
  **When** I set "Allow in Opposing-Views lane" to off (the default)
  **Then** the post is never sampled into the Opposing-Views lane for non-mutuals

- **Given** a published post is opted out
  **When** the sampling engine runs
  **Then** the post is skipped for Opposing-Views distribution regardless of interest match

## Notes
Default state is opted-out; users must affirmatively opt in (US-412).
