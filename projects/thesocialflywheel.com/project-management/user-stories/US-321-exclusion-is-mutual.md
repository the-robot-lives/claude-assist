---
id: US-321
title: "Belief Exclusion Is Mutual Between Both Users"
slug: exclusion-is-mutual
personas: [P-001]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, exclusion, mutuality, privacy]
---

# US-321: Belief Exclusion Is Mutual Between Both Users

## User Story

**As a** bridge-builder
**I want to** know that when I exclude a belief from my Opposing-Views Lane, the person holding that belief also cannot see my content on that topic in their lane
**So that** the exclusion is fair and I do not unknowingly appear in someone else's lane on a topic I chose not to engage with

## Acceptance Criteria

- **Given** I exclude belief B from my lane
  **When** the system evaluates what appears in other users' lanes
  **Then** my posts tagged with belief B are also excluded from being shown to others in their Opposing-Views Lane on that belief

- **Given** the mutual exclusion is in effect
  **When** I remove belief B from my exclusion list
  **Then** the mutual exclusion also lifts and my posts may appear in others' lanes again

## Notes
This mutuality must be communicated plainly in the exclusion flow: "Excluding this also removes your related posts from others' Opposing-Views Lanes."
