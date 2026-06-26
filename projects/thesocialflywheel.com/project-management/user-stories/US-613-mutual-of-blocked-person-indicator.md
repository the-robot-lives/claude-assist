---
id: US-613
title: "Mutual-of-Blocked-Person Indicator"
slug: mutual-of-blocked-person-indicator
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: should-have
complexity: medium
tags: [safety, blocking, social-graph]
---

# US-613: Mutual-of-Blocked-Person Indicator

## User Story

**As a** cautious newcomer
**I want to** see a subtle indicator on profiles that are mutuals of someone I have blocked
**So that** I can make an informed decision about interactions with people in the blocked person's network

## Acceptance Criteria

- **Given** I have blocked User X
  **When** I view the profile of User Y who is a direct mutual of User X
  **Then** a discreet "Mutual of a blocked person" label appears on User Y's profile card

- **Given** I remove the block on User X
  **When** I view User Y's profile
  **Then** the indicator is no longer displayed

## Notes
The indicator does not reveal the identity of the blocked person.
