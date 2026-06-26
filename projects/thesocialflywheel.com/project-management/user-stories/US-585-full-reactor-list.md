---
id: US-585
title: "See Full Reactor List for a Post"
slug: full-reactor-list
personas: [P-009]
epic: "Reactions & Engagement"
priority: should-have
complexity: medium
tags: [reactions, transparency, creator]
---

# US-585: See Full Reactor List for a Post

## User Story

**As a** Creator
**I want to** view the full list of people who reacted to my post
**So that** I know who in my community is engaging with my content

## Acceptance Criteria

- **Given** I tap the reaction count on my own post
  **When** the reactor sheet opens
  **Then** I see a list grouped by emoji showing all reactors within my web with their profile links

- **Given** a reactor has set reaction privacy to "Only me"
  **Then** they appear as "Anonymous" in my list with no profile link or avatar

## Notes
Out-of-web reactors are never shown by name regardless of their own privacy settings. List is paginated at 50 per group.
