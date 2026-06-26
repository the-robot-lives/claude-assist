---
id: US-637
title: "Screen-Reader Announcements for Safety Actions"
slug: screen-reader-announcements-for-safety-actions
personas: [P-008]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, accessibility]
---

# US-637: Screen-Reader Announcements for Safety Actions

## User Story

**As an** accessibility-first user
**I want to** hear screen-reader announcements when safety actions complete
**So that** I receive clear confirmation of blocks, mutes, and exclusions without relying on visual feedback alone

## Acceptance Criteria

- **Given** I complete a block action
  **When** the block is confirmed
  **Then** an ARIA live region announces "[Username] has been blocked" within 500ms

- **Given** I remove an exclusion
  **When** the change is saved
  **Then** the screen reader announces "Exclusion removed for [tag name]"

## Notes
Live regions should use role="status" (polite) for confirmations and role="alert" (assertive) for failure states.
