---
id: US-250
title: "Degree-Aware Channel Member List"
slug: degree-aware-channel-member-list
personas: [P-007]
epic: "Mutuals Graph & Degrees"
priority: could-have
complexity: medium
tags: [channels, graph, degrees]
---

# US-250: Degree-Aware Channel Member List

## User Story

**As a** Channel Moderator (P-007)
**I want to** see each channel member's degree of separation from me in the member list
**So that** I can identify bridge members who connect disparate parts of the community and prioritize outreach accordingly

## Acceptance Criteria

- **Given** I open the member list of a channel I moderate
  **When** the list renders
  **Then** each member entry shows their degree badge (1st, 2nd, 3rd, 4th, or "Outside web") relative to me

- **Given** I filter the member list by degree
  **When** I select "1st degree only"
  **Then** only members who are my direct mutuals are shown, all others are hidden

- **Given** a member is outside my web
  **When** their entry is shown
  **Then** "Outside web" is displayed in place of a degree number, with no mutual count

## Notes
Degree-aware member lists help moderators understand community structure and identify influential connectors. Degree data must update within one session if a new mutual connection is formed during the session.
