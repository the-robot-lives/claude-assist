---
id: US-006
title: "Suggest Adjacent Topics After a Query"
slug: suggest-adjacent-topics-after-query
personas: [P-002, P-005]
epic: "Calibrated Q&A"
priority: should-have
complexity: medium
tags: [topic-expander, sub-agent, discovery]
---

# US-006: Suggest Adjacent Topics After a Query

## User Story

**As a** developer upskilling in a new area
**I want to** have the topic-expander sub-agent suggest adjacent topics after a query
**So that** I can discover what to learn next without having to know what to ask for

## Acceptance Criteria

- **Given** a `/query` answer completes
  **When** the topic-expander sub-agent runs
  **Then** it lists 2-5 adjacent topics relevant to the question asked

- **Given** I select a suggested adjacent topic
  **When** I confirm the selection
  **Then** a follow-up `/query` is triggered for that topic

- **Given** the current domain has no clear adjacent topics
  **When** topic-expander runs
  **Then** it silently skips suggestions instead of forcing irrelevant ones

## Notes
Suggestions should factor in the user's existing KB coverage to avoid repeating topics already well-documented.
