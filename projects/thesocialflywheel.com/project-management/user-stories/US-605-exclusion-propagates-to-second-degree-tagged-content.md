---
id: US-605
title: "Exclusion Propagates to Second-Degree Tagged Content"
slug: exclusion-propagates-to-second-degree-tagged-content
personas: [P-006]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: high
tags: [safety, exclusions, cascade]
---

# US-605: Exclusion Propagates to Second-Degree Tagged Content

## User Story

**As a** quiet consumer
**I want to** have my interest exclusion cascade through second-degree connections for tagged content
**So that** posts from mutuals-of-mutuals carrying an excluded tag do not reach me via the Discovery lane

## Acceptance Criteria

- **Given** I have excluded interest #Politics
  **When** a second-degree connection publishes a post tagged #Politics
  **Then** that post does not appear in my Discovery lane

- **Given** the cascade is active
  **When** a second-degree user shares a repost tagged #Politics from outside my network
  **Then** that repost is also suppressed

## Notes
Cascade depth is expanded in US-606.
