---
id: US-762
title: "Weight Interest Priority"
slug: weight-interest-priority
personas: [P-001]
epic: "Settings & Preferences"
priority: should-have
complexity: medium
tags: [interests, personalization, algorithm, weighting]
---

# US-762: Weight Interest Priority

## User Story

**As a** bridge-builder
**I want to** adjust the relative weight of each of my interests
**So that** the algorithm emphasizes my highest-priority topics without dropping the others entirely.

## Acceptance Criteria

- **Given** I have multiple interests listed
  **When** I drag an interest to a higher position or assign it a weight value of 1–5
  **Then** the feed reflects the new weighting on next refresh.

- **Given** I set all interests to equal weight
  **When** I view my feed
  **Then** content from each interest appears with roughly equal frequency.

## Notes
Weight changes apply to Discovery and Swipe lanes but not to Mutuals lane, which shows all mutual content.
