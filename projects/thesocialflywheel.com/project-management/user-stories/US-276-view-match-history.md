---
id: US-276
title: "View Match History"
slug: view-match-history
personas: [P-003]
epic: "Swipe-to-Match"
priority: could-have
complexity: low
tags: [history, match-management, transparency]
---

# US-276: View Match History

## User Story

**As a** Social Connector (P-003)
**I want to** view a history of my past swipe-lane matches and their current status
**So that** I can track which connections originated from the Swipe-to-Match lane

## Acceptance Criteria

- **Given** I have had at least one mutual connection formed via swipe-to-match
  **When** I open Match History
  **Then** I see a chronological list of matched pairs with the date matched and current mutual status

- **Given** a former mutual has removed me from their connections
  **When** I view match history
  **Then** the entry shows "No longer mutual" without exposing why
