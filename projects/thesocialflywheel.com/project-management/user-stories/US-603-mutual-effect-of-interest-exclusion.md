---
id: US-603
title: "Mutual Effect of Interest Exclusion"
slug: mutual-effect-of-interest-exclusion
personas: [P-001]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: high
tags: [safety, exclusions, mutuality]
---

# US-603: Mutual Effect of Interest Exclusion

## User Story

**As a** bridge-builder
**I want to** understand that when I exclude an interest the other party also stops seeing my tagged posts
**So that** exclusions are symmetric and neither side is silently exposed to the other

## Acceptance Criteria

- **Given** User A excludes interest tag #X
  **When** User B (associated with #X) views their feed
  **Then** User A's posts tagged #X no longer appear in User B's lanes

- **Given** the mutual exclusion is in effect
  **When** User A removes the exclusion
  **Then** the symmetric suppression lifts for both parties

## Notes
The mutual effect applies to tagged content only, not direct messages between mutuals.
