---
id: US-034
title: "Reorder and deprecate attributes safely"
slug: reorder-and-deprecate-attributes
personas: [P-004]
epic: "Lists & Attributes"
priority: should-have
complexity: medium
tags: [attribute, reorder, deprecate, backward-compat]
---

# US-034: Reorder and deprecate attributes safely

## User Story

**As a** Service editor
**I want to** reorder attributes and retire ones I no longer need
**So that** the form stays clean without breaking existing signups

## Acceptance Criteria

- **Given** a List with several attributes
  **When** I reorder them
  **Then** the public form reflects the new order
- **Given** I deprecate/hide an attribute
  **When** the public form renders
  **Then** the attribute no longer appears but existing signup values are retained
- **Given** a deprecated attribute
  **When** I view historical signups
  **Then** its captured values are still visible

## Notes
No-migration model means retiring a field never drops stored jsonb values.
