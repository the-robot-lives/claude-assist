---
id: US-595
title: "See a Thread Summary for Long Discussions"
slug: thread-summary-long-discussion
personas: [P-006]
epic: "Reactions & Engagement"
priority: could-have
complexity: high
tags: [threading, AI, summary, readability]
---

# US-595: See a Thread Summary for Long Discussions

## User Story

**As a** Quiet Consumer
**I want to** see an AI-generated summary of a long thread
**So that** I can catch up quickly without reading every reply

## Acceptance Criteria

- **Given** a thread has more than 20 replies
  **When** I tap "Summarise thread"
  **Then** an AI-generated summary of the key discussion points appears above the reply list

- **Given** the summary is displayed
  **When** I tap a point in the summary
  **Then** I am scrolled to the most relevant reply in the thread

## Notes
Summary is generated on-demand (not proactively) to control cost. Threads flagged for moderation review do not show summaries until resolved.
