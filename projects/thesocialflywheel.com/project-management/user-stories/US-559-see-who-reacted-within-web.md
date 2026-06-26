---
id: US-559
title: "See Who Reacted Within My Web"
slug: see-who-reacted-within-web
personas: [P-009]
epic: "Reactions & Engagement"
priority: should-have
complexity: medium
tags: [reactions, social-graph, transparency]
---

# US-559: See Who Reacted Within My Web

## User Story

**As a** Creator
**I want to** see which of my mutual connections reacted to my post
**So that** I understand my audience's response and can follow up meaningfully

## Acceptance Criteria

- **Given** my post has reactions
  **When** I tap the reaction count
  **Then** I see a list of reactors who are within my mutuals web, grouped by emoji type

- **Given** a reactor is outside my web
  **Then** their identity is anonymised as "Someone outside your web reacted" with no profile link

## Notes
Full identity revealed only within the web per privacy defaults. Reactor privacy settings (US-560) override this list.
