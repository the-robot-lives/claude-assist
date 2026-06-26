---
id: US-953
title: "View Post Reach by Interest Channel"
slug: view-post-reach-by-interest-channel
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: medium
tags: [analytics, posts, interests]
---

# US-953: View Post Reach by Interest Channel

## User Story

**As a** Creator
**I want to** see a breakdown of my post's reach per interest channel
**So that** I know which communities are most receptive to my content.

## Acceptance Criteria

- **Given** a post tagged with multiple interest channels
  **When** I open its analytics
  **Then** I see impression counts per interest channel sorted descending.

- **Given** a post with no interest tags
  **When** viewing the interest breakdown
  **Then** a message indicates no channel attribution is available.

## Notes
Interest channel attribution is based on the viewer's primary active channel at time of impression.
