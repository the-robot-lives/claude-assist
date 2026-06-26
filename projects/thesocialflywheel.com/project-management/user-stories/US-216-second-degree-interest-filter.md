---
id: US-216
title: "Second-Degree Interest Filter"
slug: second-degree-interest-filter
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: medium
tags: [feed, degrees, interests]
---

# US-216: Second-Degree Interest Filter

## User Story

**As a** Bridge-Builder (P-001)
**I want to** see posts from 2nd-degree mutuals only when they match my subscribed interests
**So that** my feed stays relevant even as my mutual web grows beyond my immediate circle

## Acceptance Criteria

- **Given** a 2nd-degree mutual publishes a post tagged with an interest I subscribe to
  **When** my feed is refreshed
  **Then** the post appears in my feed with a "2nd degree" label

- **Given** a 2nd-degree mutual publishes a post that does not match any of my interests
  **When** my feed is refreshed
  **Then** the post does not appear (it is filtered out silently)
