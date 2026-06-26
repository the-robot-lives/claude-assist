---
id: US-382
title: "Blocked Users Extended Network Excluded"
slug: blocked-users-extended-network-excluded
personas: [P-005]
epic: "Discovery Engine"
priority: must-have
complexity: high
tags: [discovery, safety, graph, blocking]
---

# US-382: Blocked Users Extended Network Excluded

## User Story

**As a** Debate Seeker
**I want to** ensure that content from the immediate network of a blocked user is also deprioritized in discovery
**So that** blocking someone meaningfully reduces my exposure to their social circle, not just their own posts

## Acceptance Criteria

- **Given** I have blocked user A
  **When** the discovery engine evaluates items for my feed
  **Then** it excludes content authored by user A's 1st-degree mutuals when the primary connection path to those accounts runs through user A

- **Given** a 2nd-degree mutual is reachable through both a blocked user and an unblocked path
  **When** the engine evaluates that account's content
  **Then** the content remains eligible for discovery via the unblocked path

## Notes
This only applies to discovery sourcing, not to the social graph itself. Users reachable through non-blocked paths retain full discovery eligibility.
