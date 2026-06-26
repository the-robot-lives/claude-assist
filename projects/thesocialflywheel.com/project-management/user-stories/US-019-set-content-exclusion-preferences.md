---
id: US-019
title: "Set Content Exclusion Preferences"
slug: set-content-exclusion-preferences
personas: [P-004, P-008, P-006]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [exclusion, content-safety, onboarding, preferences]
---

# US-019: Set Content Exclusion Preferences

## User Story

**As a** cautious newcomer
**I want to** mark certain interests or belief topics as excluded during onboarding
**So that** content tagged with those topics never appears in my feed across any lane

## Acceptance Criteria

- **Given** I am on the exclusion preferences screen
  **When** I select an interest or belief tag to exclude
  **Then** a confirmation message explains the cascade: all content tagged with that topic — including from outer-degree mutuals — will be hidden.

- **Given** I save my exclusions
  **When** I enter a channel that has an excluded tag
  **Then** posts bearing that tag are hidden and a "Some posts hidden" indicator is shown at the lane level.

## Notes
Exclusions must cascade to tagged content, not just channels. Exclusions do not sever existing mutual relationships. Users can update exclusions at any time in settings.
