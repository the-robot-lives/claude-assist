---
id: US-372
title: "Auto-Reduce Discovery When Overwhelmed"
slug: auto-reduce-discovery-when-overwhelmed
personas: [P-006]
epic: "Discovery Engine"
priority: should-have
complexity: high
tags: [discovery, balance, automation]
---

# US-372: Auto-Reduce Discovery When Overwhelmed

## User Story

**As a** Quiet Consumer
**I want to** have the engine automatically reduce discovery volume when my engagement signals indicate I am overwhelmed
**So that** I do not need to manually adjust settings every time I need a lighter experience

## Acceptance Criteria

- **Given** I have dismissed or ignored more than 80% of discovery items over a 7-day window without liking any
  **When** the engine evaluates my engagement pattern
  **Then** it automatically halves the discovery density for the following week and shows a subtle notification informing me

- **Given** the engine has auto-reduced my discovery volume
  **When** my engagement rate improves over the subsequent 7 days
  **Then** the engine gradually restores the volume toward my configured setting

## Notes
Auto-reduction should notify the user once with a dismissible banner, not with a push notification.
