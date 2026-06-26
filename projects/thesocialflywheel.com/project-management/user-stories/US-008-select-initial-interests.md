---
id: US-008
title: "Select Initial Interests"
slug: select-initial-interests
personas: [P-004, P-002, P-001]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [interests, onboarding, personalization]
---

# US-008: Select Initial Interests

## User Story

**As a** cautious newcomer
**I want to** choose at least three interests from a curated list
**So that** Flywheel can populate my feed with relevant channels from day one

## Acceptance Criteria

- **Given** I am on the interest selection screen
  **When** I tap interest tiles and have selected 3 or more
  **Then** the "Continue" button becomes active.

- **Given** I select an interest
  **When** it is added
  **Then** related sub-interests expand inline so I can refine my selection without leaving the screen.

## Notes
Display 30–50 top interests initially; "show more" reveals the full catalog. Pre-select nothing — avoid biasing the user.
