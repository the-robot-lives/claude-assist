---
id: US-237
title: "Suggest Mutuals via Shared Channels"
slug: suggest-mutuals-via-shared-channels
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: should-have
complexity: high
tags: [discovery, graph, channels]
---

# US-237: Suggest Mutuals via Shared Channels

## User Story

**As a** Bridge-Builder (P-001)
**I want to** receive mutual suggestions based on active members in channels I participate in
**So that** I can grow my web with people who share my interests organically

## Acceptance Criteria

- **Given** I am an active member of one or more interest channels
  **When** I visit the Discover section
  **Then** I see a "From your channels" suggestion section featuring users who post frequently in channels I follow and are not yet my mutuals

- **Given** a channel-based suggestion is shown
  **When** I view the user card
  **Then** the card lists which shared channel(s) surfaced the suggestion (e.g., "Both active in #Typography")

- **Given** I dismiss a suggestion
  **When** I tap "Not interested"
  **Then** that user is not suggested again for at least 60 days

## Notes
Suggestions must be based on mutual channel activity, not just membership. A user who joined but never posted should not be surfaced.
