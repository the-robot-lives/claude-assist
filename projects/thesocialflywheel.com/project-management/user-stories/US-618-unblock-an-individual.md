---
id: US-618
title: "Unblock an Individual"
slug: unblock-an-individual
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: low
tags: [safety, unblock]
---

# US-618: Unblock an Individual

## User Story

**As a** cautious newcomer
**I want to** unblock a previously blocked user
**So that** I can restore normal interaction if the situation has changed

## Acceptance Criteria

- **Given** User X appears in my Blocked Users list
  **When** I select "Unblock" and confirm
  **Then** User X is removed from the list and the block (including any cascade) is lifted immediately

- **Given** the unblock is complete
  **When** User X views Discovery
  **Then** content routing is restored as if the block never existed

## Notes
Unblocking does not automatically re-mutual; mutual status must be re-established separately.
