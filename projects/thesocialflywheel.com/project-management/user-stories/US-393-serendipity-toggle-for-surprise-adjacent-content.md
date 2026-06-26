---
id: US-393
title: "Serendipity Toggle for Surprise Adjacent Content"
slug: serendipity-toggle-for-surprise-adjacent-content
personas: [P-001]
epic: "Discovery Engine"
priority: could-have
complexity: medium
tags: [discovery, serendipity, settings]
---

# US-393: Serendipity Toggle for Surprise Adjacent Content

## User Story

**As a** Bridge-Builder
**I want to** enable a Serendipity mode that occasionally surfaces content two or more interest hops away from my current profile
**So that** I am pleasantly surprised by unexpected topics I would not have found through normal adjacency discovery

## Acceptance Criteria

- **Given** I enable Serendipity mode in Discovery Settings
  **When** the engine selects discovery items
  **Then** up to 20% of discovery slots are allocated to content that is two or more conceptual hops from my declared interests, still within the 4th-degree mutual boundary

- **Given** Serendipity mode is active
  **When** I dislike a serendipitous item
  **Then** the engine records the dislike against the distant topic but does not increase its future serendipity allocation

## Notes
Serendipity mode is off by default. When enabled, the engine should label serendipitous items with "Serendipity pick" to distinguish them from standard adjacent content.
