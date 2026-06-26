---
id: US-459
title: "Sort feed by recency (reverse-chronological)"
slug: sort-feed-by-recency
personas: [P-003, P-009]
epic: "Feed & Ranking"
priority: should-have
complexity: low
tags: [sort, recency, feed-control]
---

# US-459: Sort Feed by Recency (Reverse-Chronological)

## User Story

**As a** social connector (P-003)
**I want to** switch the feed to strict reverse-chronological order
**So that** I never miss a recent post from anyone in my network

## Acceptance Criteria

- **Given** the home feed is in ranked mode
  **When** I select "Newest first" from the sort menu
  **Then** posts reorder with the most recently published at the top, ignoring degree/interest weights

- **Given** "Newest first" is active
  **When** a new post arrives
  **Then** it inserts at the top of the feed immediately (or after tapping the new-post indicator)

## Notes
Recency sort applies within the current active filter (e.g., mutuals-only + newest first is valid).
