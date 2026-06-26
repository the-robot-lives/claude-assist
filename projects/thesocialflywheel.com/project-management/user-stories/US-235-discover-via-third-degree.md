---
id: US-235
title: "Discover via Third Degree"
slug: discover-via-third-degree
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: could-have
complexity: medium
tags: [discovery, graph, degrees]
---

# US-235: Discover via Third Degree

## User Story

**As a** Social Connector (P-003)
**I want to** explore 3rd-degree users in my network as potential connection targets
**So that** I can proactively reach out and pull interesting people closer into my web

## Acceptance Criteria

- **Given** I open the "Discover" section and select "3rd degree"
  **When** the list loads
  **Then** I see up to 50 3rd-degree users ranked by shared interest overlap with me

- **Given** a 3rd-degree user appears in the list
  **When** I view their card
  **Then** I see the connection path (e.g., "Via Alice → Bob"), their shared interests, and an "Add Mutual" button

## Notes
3rd-degree discovery is secondary to 2nd-degree; show it as a secondary tab or "Expand further" section rather than the default view.
