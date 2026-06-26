---
id: US-622
title: "Dislike Refines Recommendations Without Blocking User"
slug: dislike-refines-recommendations-without-blocking-user
personas: [P-001]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: medium
tags: [safety, discovery, dislike]
---

# US-622: Dislike Refines Recommendations Without Blocking User

## User Story

**As a** bridge-builder
**I want to** signal a dislike on a topic without blocking the author
**So that** I can reduce unwanted content from my feed while preserving my relationship with that person

## Acceptance Criteria

- **Given** I tap "Not interested in #Topic" on a post
  **When** the preference signal is saved
  **Then** the author remains in my Mutuals lane and our mutual relationship is unchanged

- **Given** the author posts on a different topic
  **When** Discovery runs
  **Then** their non-disliked content still surfaces normally

## Notes
Dislike is topic-scoped, not user-scoped. This distinguishes it from muting (US-624).
