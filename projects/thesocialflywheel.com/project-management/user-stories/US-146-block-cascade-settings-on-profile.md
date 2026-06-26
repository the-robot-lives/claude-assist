---
id: US-146
title: "Block cascade settings on profile"
slug: block-cascade-settings-on-profile
personas: [P-004]
epic: "Profile & Identity"
priority: should-have
complexity: medium
tags: [profile, identity, safety, privacy]
---

# US-146: Block Cascade Settings on Profile

## User Story

**As a** cautious newcomer
**I want to** see and configure my block cascade settings from my profile
**So that** I understand whether blocking someone also affects their mutuals before I act

## Acceptance Criteria

- **Given** I open my profile safety settings
  **When** I view the block cascade option
  **Then** I see a clear explanation of what cascade does and its current on/off state

- **Given** cascade is enabled
  **When** I block a member
  **Then** I am shown how many mutual connections will also be affected before confirming

## Notes
Surfaces the existing block-cascade behavior in a discoverable place; the default cascade scope is conservative.
