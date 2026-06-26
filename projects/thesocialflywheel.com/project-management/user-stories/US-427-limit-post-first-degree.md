---
id: US-427
title: "Limit post visibility to first-degree mutuals only"
slug: limit-post-first-degree
personas: [P-006]
epic: "Posting & Content Creation"
priority: must-have
complexity: low
tags: [privacy, visibility, 1st-degree, audience]
---

# US-427: Limit Post Visibility to First-Degree Mutuals Only

## User Story

**As a** Quiet Consumer
**I want to** publish a post that only my direct mutuals can see
**So that** my content stays within my trusted inner circle and does not propagate further

## Acceptance Criteria

- **Given** I am composing a post
  **When** I set Audience to "1st Degree Only"
  **Then** only users I have a confirmed mutual connection with can see the post

- **Given** the post is published with 1st-degree restriction
  **When** the propagation engine runs
  **Then** the post is never forwarded to 2nd-degree or beyond, regardless of interest tags

## Notes
1st-degree-only posts are also excluded from Opposing-Views and Discovery lanes by default.
