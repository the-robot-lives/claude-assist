---
id: US-390
title: "Prompt to Expand Network When Pool Is Thin"
slug: prompt-to-expand-network-when-pool-is-thin
personas: [P-001]
epic: "Discovery Engine"
priority: should-have
complexity: medium
tags: [discovery, graph, growth]
---

# US-390: Prompt to Expand Network When Pool Is Thin

## User Story

**As a** Bridge-Builder
**I want to** receive a prompt to connect with more people when the discovery engine cannot find enough content within my 4th-degree network
**So that** I understand why discovery is thin and have a clear action to improve it

## Acceptance Criteria

- **Given** the discovery engine finds fewer than three eligible discovery items in my 4th-degree network for the current rotation
  **When** my feed loads
  **Then** a contextual prompt is shown suggesting I connect with more people or join more channels to enrich my network

- **Given** the thin-pool prompt is shown
  **When** I tap "Find people to follow"
  **Then** I am taken to the Swipe-to-Match lane with a contextual note explaining why I was directed there

## Notes
The prompt should appear at most once per feed session to avoid nagging.
