---
id: US-045
title: "Interest Refinement After Initial Selection"
slug: interest-refinement-after-initial-selection
personas: [P-002, P-001, P-010]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: low
tags: [interests, refinement, settings, onboarding]
---

# US-045: Interest Refinement After Initial Selection

## User Story

**As a** skeptical switcher
**I want to** be able to revise my interest selections after completing onboarding
**So that** I can course-correct if my initial picks do not reflect what I actually enjoy

## Acceptance Criteria

- **Given** I completed onboarding with specific interests
  **When** I navigate to Settings > Interests
  **Then** I can add, remove, or reorder interests and the change takes effect in my feed within 5 minutes.

- **Given** I remove an interest
  **When** the change saves
  **Then** channels based only on that removed interest are unsubscribed automatically with a confirmation toast listing what was removed.

## Notes
Keep the interest edit UI consistent with the onboarding selection UI to reduce learning curve. Removing all interests below 3 should prompt "You need at least 3 interests" before saving.
