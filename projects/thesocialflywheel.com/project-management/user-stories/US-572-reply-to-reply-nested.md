---
id: US-572
title: "Reply to a Reply (Nested Threading)"
slug: reply-to-reply-nested
personas: [P-001]
epic: "Reactions & Engagement"
priority: should-have
complexity: medium
tags: [threading, nested-replies, discussion]
---

# US-572: Reply to a Reply (Nested Threading)

## User Story

**As a** Bridge-Builder
**I want to** reply directly to someone's reply
**So that** I can have focused sub-conversations without derailing the main thread

## Acceptance Criteria

- **Given** I am viewing a reply
  **When** I tap Reply on that specific reply
  **Then** my response is nested one level deeper and auto-mentions the parent replier

- **Given** nesting exceeds 5 levels
  **Then** the Reply button is replaced with "Continue thread" which opens a flat new reply at the top level of the same thread

## Notes
Deep nesting collapses by default after level 3; user can expand with a tap. See US-573 for full thread collapse.
