---
id: US-647
title: "Block List Invisible to Mutual Network"
slug: block-list-invisible-to-mutual-network
personas: [P-006]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: medium
tags: [safety, privacy, blocking]
---

# US-647: Block List Invisible to Mutual Network

## User Story

**As a** quiet consumer
**I want to** ensure that my mutuals cannot see who I have blocked
**So that** safety actions I take do not affect my relationships or cause third-party drama

## Acceptance Criteria

- **Given** I have blocked User X who is also a mutual of User Y
  **When** User Y views my profile or our shared channel
  **Then** nothing reveals that I have blocked User X

- **Given** User Y is also a mutual of User X
  **When** User Y views User X's profile
  **Then** no indication of my block on User X is surfaced

## Notes
The "mutual of blocked person" indicator (US-613) only surfaces to the person who placed the block, not to shared connections.
