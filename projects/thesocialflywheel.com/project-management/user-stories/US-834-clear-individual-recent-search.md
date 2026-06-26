---
id: US-834
title: "Remove Individual Recent Search Item"
slug: clear-individual-recent-search
personas: [P-006]
epic: "Search & Find"
priority: could-have
complexity: low
tags: [search, history, remove, recents]
---

# US-834: Remove Individual Recent Search Item

## User Story

**As a** quiet consumer
**I want to** delete a single entry from my recent search history
**So that** I can keep my history tidy without wiping everything

## Acceptance Criteria

- **Given** recent searches are shown
  **When** I click the ✕ on one item
  **Then** that item is removed from the list immediately without a page refresh

- **Given** I remove an item using the keyboard (Tab to ✕, Enter)
  **When** the item is deleted
  **Then** focus moves to the next item or back to the search input if no items remain

## Notes
Deletion is instant and not reversible; no confirmation dialog needed for a single item.
