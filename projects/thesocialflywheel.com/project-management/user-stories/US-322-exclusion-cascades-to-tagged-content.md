---
id: US-322
title: "Exclusion Cascades to Content Tagged with Excluded Belief"
slug: exclusion-cascades-to-tagged-content
personas: [P-007]
epic: "Opposing-Views Lane"
priority: must-have
complexity: high
tags: [opposing-views, exclusion, cascade, tags, moderation]
---

# US-322: Exclusion Cascades to Content Tagged with Excluded Belief

## User Story

**As a** channel moderator
**I want to** trust that when a user excludes a belief, any content tagged with that belief is also excluded from the Opposing-Views Lane even if it matches on a secondary interest
**So that** exclusions cannot be circumvented by multi-tagged posts

## Acceptance Criteria

- **Given** user U has excluded belief B
  **When** a post is tagged with both belief B and non-excluded interest I
  **Then** the post does not appear in U's Opposing-Views Lane

- **Given** a channel has a channel-level belief exclusion set by the moderator
  **When** a post is tagged with that belief
  **Then** it is excluded from the Opposing-Views Lane for all members of that channel regardless of individual settings

## Notes
Channel-level exclusion is additive with individual exclusions and cannot be overridden by individual user settings.
