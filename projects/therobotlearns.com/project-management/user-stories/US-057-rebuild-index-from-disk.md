---
id: US-057
title: "Rebuild index.yaml from Files on Disk"
slug: rebuild-index-from-disk
personas: [P-006, P-001]
epic: "KB Maintenance"
priority: must-have
complexity: medium
tags: [index, repair, cli]
---

# US-057: Rebuild index.yaml from Files on Disk

## User Story

**As a** staff backend engineer whose index.yaml has drifted from the actual files
**I want to** regenerate the index by scanning the KB directory directly
**So that** `/query` and browsing reflect what's really on disk, not a stale record

## Acceptance Criteria

- **Given** index.yaml references articles that no longer exist on disk
  **When** I run the rebuild-index command
  **Then** the stale entries are removed and the resulting index only lists files actually present

- **Given** several valid articles exist on disk but are missing from index.yaml
  **When** I run the rebuild-index command
  **Then** those articles are added to the index with metadata read from their own front matter

- **Given** the rebuild would remove or change more than a threshold percentage of entries
  **When** the command runs
  **Then** I'm shown a summary of additions/removals and asked to confirm before the index file is overwritten

- **Given** the rebuild completes successfully
  **When** I inspect the flashcard deck index separately
  **Then** it is rebuilt using the same on-disk-scan logic, independent of the KB article index

## Notes
Should preserve any index fields that can't be derived from disk (e.g., manual ordering hints) where possible.
