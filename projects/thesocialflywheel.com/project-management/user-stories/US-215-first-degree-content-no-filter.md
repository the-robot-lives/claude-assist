---
id: US-215
title: "First-Degree Content No Filter"
slug: first-degree-content-no-filter
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: low
tags: [feed, degrees, content-visibility]
---

# US-215: First-Degree Content No Filter

## User Story

**As a** Social Connector (P-003)
**I want to** see all posts from my 1st-degree mutuals in my feed without any interest filter applied
**So that** I never miss content from the people I have explicitly chosen to connect with

## Acceptance Criteria

- **Given** a 1st-degree mutual posts in any channel or topic
  **When** my feed is refreshed
  **Then** that post appears in my Mutuals lane regardless of whether the topic matches my interest subscriptions

- **Given** I have excluded an interest globally
  **When** a 1st-degree mutual posts content tagged with that interest
  **Then** the post still appears in my Mutuals lane (exclusions apply only to outer-degree content)

## Notes
Interest exclusions (US-220) intentionally do not override 1st-degree visibility — this preserves the value of direct mutual connections.
