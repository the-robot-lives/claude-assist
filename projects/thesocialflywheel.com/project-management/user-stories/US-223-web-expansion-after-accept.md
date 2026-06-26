---
id: US-223
title: "Web Expansion After Accept"
slug: web-expansion-after-accept
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: high
tags: [graph, discovery, expansion]
---

# US-223: Web Expansion After Accept

## User Story

**As a** Social Connector (P-003)
**I want to** be shown how my reachable web expands after I accept a mutual request
**So that** I understand the concrete benefit of adding this new connection

## Acceptance Criteria

- **Given** I accept a mutual request
  **When** the connection is confirmed
  **Then** a summary notification or inline card states "Your web grew! +N new users now reachable" reflecting newly accessible 2nd-degree connections via the new mutual

- **Given** the web expansion summary is shown
  **When** I tap "See who's new"
  **Then** I see a list of newly reachable users (their profiles, degree from me) introduced through the new mutual

## Notes
Expansion summary is delivered as a one-time notification tied to the accept event, not a persistent UI element.
