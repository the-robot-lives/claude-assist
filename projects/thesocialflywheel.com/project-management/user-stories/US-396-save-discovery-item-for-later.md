---
id: US-396
title: "Save Discovery Item for Later"
slug: save-discovery-item-for-later
personas: [P-002]
epic: "Discovery Engine"
priority: could-have
complexity: low
tags: [discovery, bookmarks]
---

# US-396: Save Discovery Item for Later

## User Story

**As a** Niche Enthusiast
**I want to** bookmark a discovery item to read later without sending a positive signal to the engine
**So that** I can revisit interesting content at my own pace without accidentally affecting my discovery profile

## Acceptance Criteria

- **Given** a discovery item is visible in my feed
  **When** I tap the bookmark icon on the card
  **Then** the item is added to my Saved Items list and a confirmation toast appears

- **Given** I have bookmarked a discovery item
  **When** I navigate to my Saved Items
  **Then** the item appears there labeled as "Saved from Discovery" with its surfacing reason preserved

## Notes
Bookmarking does not count as a like signal. It is a neutral save action with no effect on the discovery topic model.
