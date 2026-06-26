---
id: US-641
title: "Export Block and Exclusion List"
slug: export-block-and-exclusion-list
personas: [P-010]
epic: "Safety: Blocking & Exclusions"
priority: could-have
complexity: medium
tags: [safety, management, export]
---

# US-641: Export Block and Exclusion List

## User Story

**As a** skeptical switcher migrating from another platform
**I want to** export my block and exclusion lists as a file
**So that** I can keep a personal record or potentially import them elsewhere

## Acceptance Criteria

- **Given** I am on Settings > Safety
  **When** I select "Export safety data"
  **Then** a CSV file is generated containing my blocked users (username, date) and excluded tags (tag, date, lanes)

- **Given** the export is generated
  **When** I download it
  **Then** the file does not contain any data about the blocked users beyond username (no profile details of blocked parties)

## Notes
Export is for personal record only; the platform does not guarantee import from other platforms yet.
