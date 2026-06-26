---
id: US-456
title: "See a 'why am I seeing this' badge on each post"
slug: why-am-i-seeing-this-badge
personas: [P-001, P-006, P-010]
epic: "Feed & Ranking"
priority: must-have
complexity: medium
tags: [transparency, ranking, badge, trust]
---

# US-456: See a "Why Am I Seeing This" Badge on Each Post

## User Story

**As a** bridge-builder (P-001)
**I want to** tap a small badge on any post to learn why it appeared in my feed
**So that** I understand the ranking logic and can trust the system is not doing hidden promotion

## Acceptance Criteria

- **Given** any post in my feed
  **When** I tap the info badge (ⓘ)
  **Then** a tooltip/sheet shows the primary reason: e.g., "From your mutual @alex", "2nd-degree in #jazz you follow", "Opposing-Views lane", or "Discovery"

- **Given** the explanation sheet is open
  **When** the reason includes degree and interest
  **Then** both signals are listed with their relative weight contribution (e.g., "Degree 2nd ×0.7, Interest match ×0.9, Recency ×0.95")

## Notes
No engagement/virality signals are exposed — only degree, interest, recency, and lane.
