---
id: US-307
title: "Mutual Exclusion Cascades to Tagged Content"
slug: mutual-exclusion-cascades-to-tagged-content
personas: [P-001]
epic: "Opposing-Views Lane"
priority: must-have
complexity: high
tags: [opposing-views, exclusion, cascade, tags]
---

# US-307: Mutual Exclusion Cascades to Tagged Content

## User Story

**As a** bridge-builder
**I want to** know that excluding a belief from the Opposing-Views Lane also removes content that is tagged with that belief, even if it matches on a different primary interest
**So that** my exclusion is comprehensive and I do not encounter the excluded topic through a side door

## Acceptance Criteria

- **Given** I have excluded belief B from my lane
  **When** a post is tagged with both belief B and interest I (where I is not excluded)
  **Then** the post does not appear in my lane despite the interest match

- **Given** a post is excluded by tag cascade
  **When** the system audits why I did not see it
  **Then** the reason is logged as "excluded belief tag: B" (internal, not shown to user)

## Notes
Tag cascade applies only to the Opposing-Views Lane. The same post may still appear in the Mutuals lane if the poster is a mutual.
