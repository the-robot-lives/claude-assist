---
id: US-036
title: "Add photos to catalog items"
slug: "catalog-photos"
personas: [P-001, P-002]
epic: "Inventory & Catalog"
priority: "could-have"
complexity: "S"
tags: [catalog, photos, ux]
---

# US-036: Add photos to catalog items

## User Story

**As a** market-stall owner (P-001) who is not comfortable reading long text quickly,
**I want to** attach a photo to each item in my catalog,
**So that** I (and my staff) can find the right item on the sell screen by recognizing its picture rather than reading its name.

## Acceptance Criteria

- [ ] Given I am adding or editing an item, when I tap the photo field, then I can take a new photo with the device camera or pick one from the gallery, with no minimum photo-editing skill required.
- [ ] Given an item has no photo, when it appears on the sell screen, then it shows a category-based placeholder icon (e.g. a drink glass for "Beverages") instead of a blank box.
- [ ] Given I am offline when adding a photo, when I save the item, then the photo is stored locally and uploads once connectivity returns, without blocking the item from being usable at the register in the meantime.
- [ ] Given storage/bandwidth constraints on cheap devices, when a photo is saved, then it is compressed to a reasonable size (e.g. under 200KB) automatically before it's stored or synced.

## Notes

Directly supports product principle "usable by a first-time smartphone user" for low-literacy or non-Khmer-reading contexts. Related: [[US-026]], [[US-042]] (AI scan flow also captures a photo, which can double as the catalog photo).
