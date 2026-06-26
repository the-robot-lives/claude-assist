---
id: US-306
title: "Exclude a Belief from the Opposing-View Lane"
slug: exclude-belief-from-opposing-view-lane
personas: [P-004]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, exclusion, belief, safety]
---

# US-306: Exclude a Belief from the Opposing-View Lane

## User Story

**As a** cautious newcomer
**I want to** mark specific beliefs or topics as excluded from the Opposing-Views Lane
**So that** I am not exposed to counter-content on subjects I find too distressing to engage with

## Acceptance Criteria

- **Given** I open my Opposing-Views Lane preferences
  **When** I add a belief/interest to the exclusion list
  **Then** no posts tied to that belief appear in my lane from that point forward

- **Given** a belief is on my exclusion list
  **When** a post would have matched on that belief
  **Then** the system silently skips it and fills the slot with a qualifying post on a non-excluded interest, or leaves it empty if none qualify

## Notes
Exclusion list is stored per user. The excluded belief should still be discoverable via Mutuals lane; this only gates the Opposing-Views Lane.
