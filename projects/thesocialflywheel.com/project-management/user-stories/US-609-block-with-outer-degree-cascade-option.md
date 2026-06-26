---
id: US-609
title: "Block with Outer-Degree Cascade Option"
slug: block-with-outer-degree-cascade-option
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: high
tags: [safety, blocking, cascade]
---

# US-609: Block with Outer-Degree Cascade Option

## User Story

**As a** cautious newcomer
**I want to** choose to extend a block to the outer-degree network of the blocked person
**So that** their mutuals-of-mutuals cannot reach me through the blocked person's network graph

## Acceptance Criteria

- **Given** I initiate a block on User X
  **When** the block confirmation dialog appears
  **Then** I am presented with a "Also limit reach of their network" toggle with a plain-language explanation

- **Given** I enable the outer-degree cascade toggle and confirm
  **When** a second-degree connection of User X visits Discovery
  **Then** content tagged with User X's interests and routed through them does not surface in my feed

- **Given** the cascade block is active
  **When** I view my block settings for User X
  **Then** the cascade depth selected is clearly displayed

## Notes
Direct mutuals are never severed regardless of cascade setting; see US-612.
