---
id: US-895
title: "Screen Reader Announcement on Degree Change"
slug: announce-degree-change
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: should-have
complexity: medium
tags: [screen-reader, moots, degrees, live-regions]
---

# US-895: Screen Reader Announcement on Degree Change

## User Story

**As a** screen-reader user
**I want to** be notified when my relationship degree with another user changes
**So that** I am aware of how my network is evolving without having to inspect the moot graph visually

## Acceptance Criteria

- **Given** I connect with a new moot who was previously a 3rd-degree connection
  **When** the connection is confirmed
  **Then** a polite live region announces "[Name] is now your 1st-degree moot"

- **Given** a moot removes their connection to me
  **When** the event is processed
  **Then** a polite announcement reads "[Name] is no longer a moot"

- **Given** a new connection causes my 2nd-degree reach to expand
  **When** the feed updates to reflect this
  **Then** a single batched announcement summarises "[N] new people are now within your 2nd-degree network" rather than announcing each individual change

## Notes
Batching prevents announcement flooding when a single connection creates many new 2nd-degree reachable users. Use a debounce window of ~3 seconds before emitting the batched count.
