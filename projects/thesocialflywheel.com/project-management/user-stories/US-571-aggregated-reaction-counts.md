---
id: US-571
title: "See Aggregated Reaction Counts on a Post"
slug: aggregated-reaction-counts
personas: [P-006]
epic: "Reactions & Engagement"
priority: must-have
complexity: low
tags: [reactions, counts, display]
---

# US-571: See Aggregated Reaction Counts on a Post

## User Story

**As a** Quiet Consumer
**I want to** see a summary of reaction counts on each post
**So that** I can gauge community sentiment at a glance without opening the full reactor list

## Acceptance Criteria

- **Given** a post has reactions
  **When** I view it in the feed
  **Then** each distinct emoji with its count is displayed below the post content

- **Given** a post has zero reactions
  **Then** no reaction summary row is shown; the empty state is clean

## Notes
Show at most 5 distinct emoji types in the inline summary; overflow into a "+N more" chip that opens the full reactor sheet.
