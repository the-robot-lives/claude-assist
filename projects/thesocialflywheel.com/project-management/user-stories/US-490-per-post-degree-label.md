---
id: US-490
title: "See the connection degree on every feed post"
slug: per-post-degree-label
personas: [P-001, P-006]
epic: "Feed & Ranking"
priority: must-have
complexity: low
tags: [degree, label, transparency, feed]
---

# US-490: See the Connection Degree on Every Feed Post

## User Story

**As a** bridge-builder (P-001)
**I want to** see a small degree indicator (1st, 2nd, 3rd, 4th, or Mutual) next to each post author
**So that** I always know how closely connected I am to the person who posted

## Acceptance Criteria

- **Given** a post from a direct mutual appears in the feed
  **When** I look at the author line
  **Then** a "Mutual" or "1st" badge is visible next to the author's name

- **Given** a post from a 3rd-degree connection appears
  **When** I look at the author line
  **Then** a "3rd" degree badge is shown

- **Given** a Discovery post from a channel I don't follow appears
  **When** it renders in the feed
  **Then** the degree label shows the correct degree if within graph, or "Discovery" if sourced outside degree tracking

## Notes
Degree labels use accessible colour coding (not colour alone) to differentiate.
