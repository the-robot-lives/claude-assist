---
id: US-475
title: "View the Opposing-Views lane"
slug: opposing-views-lane
personas: [P-001, P-005]
epic: "Feed & Ranking"
priority: must-have
complexity: high
tags: [opposing-views, lane, diversity, read-only]
---

# US-475: View the Opposing-Views Lane

## User Story

**As a** bridge-builder (P-001)
**I want to** see a curated set of posts representing viewpoints different from my own channel subscriptions
**So that** I remain exposed to perspectives outside my interest bubble

## Acceptance Criteria

- **Given** the feed is loaded
  **When** an Opposing-Views post appears
  **Then** it is clearly labelled with an "Opposing View" badge and is in read-only mode (no reply button, only read/react options)

- **Given** I encounter an Opposing-Views post I find valuable
  **When** I tap "Open in full"
  **Then** I can read the complete post but cannot reply from within the feed; I must navigate to the source channel to engage

- **Given** I set Opposing-Views ratio to 0% in lane controls
  **When** the feed reloads
  **Then** no Opposing-Views posts appear in the home feed, but the dedicated Opposing-Views lane tab remains accessible

## Notes
Opposing-Views content is sourced from posts within my 4th-degree graph in channels I do not subscribe to.
