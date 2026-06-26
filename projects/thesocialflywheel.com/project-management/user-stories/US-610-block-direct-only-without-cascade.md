---
id: US-610
title: "Block Direct-Only Without Cascade"
slug: block-direct-only-without-cascade
personas: [P-006]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: medium
tags: [safety, blocking, cascade]
---

# US-610: Block Direct-Only Without Cascade

## User Story

**As a** quiet consumer
**I want to** block someone at the direct level only, without cascading to their network
**So that** only the specific person is blocked and I do not inadvertently limit contact with unrelated connections

## Acceptance Criteria

- **Given** I block User X with cascade disabled
  **When** a mutual of User X appears in my Discovery lane
  **Then** that mutual's content is not suppressed by this block

- **Given** the direct-only block is active
  **When** I view User X's profile
  **Then** I see "Blocked (direct only)" with an option to extend the cascade

## Notes
Default block scope is direct-only unless the user opts into cascade (US-609).
