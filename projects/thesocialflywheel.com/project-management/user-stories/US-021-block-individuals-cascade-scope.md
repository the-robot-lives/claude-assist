---
id: US-021
title: "Block Individuals and Set Cascade Scope"
slug: block-individuals-cascade-scope
personas: [P-004, P-007, P-008]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [block, safety, onboarding, cascade]
---

# US-021: Block Individuals and Set Cascade Scope

## User Story

**As a** cautious newcomer
**I want to** pre-emptively block specific accounts and optionally cascade that block to outer-degree connections
**So that** I feel safe before I start engaging

## Acceptance Criteria

- **Given** I search for an account and tap "Block"
  **When** I confirm
  **Then** that account is blocked and their content is hidden across all lanes; direct mutual relationships with them are not affected.

- **Given** I choose the cascade option when blocking
  **When** confirmed
  **Then** content from users whose only path to me runs through the blocked account is also deprioritized in outer-degree lanes.

## Notes
Blocking during onboarding is optional and accessible from the safety setup screen. Blocks can be reviewed and removed in account settings.
