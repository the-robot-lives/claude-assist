---
id: US-457
title: "Filter feed to mutuals only"
slug: filter-mutuals-only
personas: [P-006, P-004]
epic: "Feed & Ranking"
priority: should-have
complexity: low
tags: [filter, mutuals, feed-control]
---

# US-457: Filter Feed to Mutuals Only

## User Story

**As a** quiet consumer (P-006)
**I want to** toggle a "Mutuals only" filter on the home feed
**So that** I can focus on close connections when I want a smaller, curated view

## Acceptance Criteria

- **Given** the home feed is showing all lanes
  **When** I enable the "Mutuals only" filter
  **Then** Discovery, Opposing-Views, and 2nd–4th degree posts are hidden and only direct-mutual posts remain

- **Given** the "Mutuals only" filter is active
  **When** I disable it
  **Then** the full blended feed restores with the previously configured lane ratios

## Notes
Filter state persists per session but resets to default on next app open.
