---
id: US-230
title: "Swipe Match Expands Web"
slug: swipe-match-expands-web
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: medium
tags: [graph, swipe-to-match, expansion]
---

# US-230: Swipe Match Expands Web

## User Story

**As a** Social Connector (P-003)
**I want to** see my mutual web automatically expand after a swipe match converts to a mutual
**So that** I benefit from the discovery potential of new connections without manual action

## Acceptance Criteria

- **Given** a swipe match converts to a 1st-degree mutual
  **When** the connection is established
  **Then** the new mutual's existing 1st-degree connections become my 2nd-degree mutuals, their 2nd-degree become my 3rd, and so on up to 4th degree

- **Given** the web expansion occurs after a swipe match
  **When** I next open my feed
  **Then** I may see new interest-filtered posts from newly reachable 2nd–4th degree users

## Notes
Web expansion from swipe matches is subject to the same degree-based filtering rules as a standard mutual request acceptance (see US-216–US-218).
