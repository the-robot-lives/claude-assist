---
id: US-375
title: "Cold-Start Interest Quiz at Onboarding"
slug: cold-start-interest-quiz-at-onboarding
personas: [P-001]
epic: "Discovery Engine"
priority: must-have
complexity: medium
tags: [discovery, cold-start, onboarding]
---

# US-375: Cold-Start Interest Quiz at Onboarding

## User Story

**As a** Bridge-Builder
**I want to** complete a short interest selection quiz during onboarding
**So that** the discovery engine has enough signal to surface relevant content before I have built a mutuals network

## Acceptance Criteria

- **Given** I am a new user completing account setup
  **When** I reach the interest selection step
  **Then** I am presented with a categorized list of topics and can select at least three to seed my discovery profile

- **Given** I complete the interest quiz and select my topics
  **When** I arrive at my feed for the first time
  **Then** discovery content is already seeded based on my selections with no empty state shown

## Notes
The quiz must be completable in under two minutes. Skipping is allowed but triggers a minimal cold-start with platform-curated popular content.
