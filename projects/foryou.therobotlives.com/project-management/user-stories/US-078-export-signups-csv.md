---
id: US-078
title: "Export signups to CSV"
slug: export-signups-csv
personas: [P-003]
epic: "Admin Console"
priority: must-have
complexity: medium
tags: [admin, signups, export, csv, backfill]
---

# US-078: Export signups to CSV

## User Story

**As a** site owner/admin
**I want to** export a list's signups to CSV
**So that** I can analyze them or use them elsewhere

## Acceptance Criteria

- **Given** a list's signups (optionally filtered)
  **When** I export to CSV
  **Then** I get a file with one row per signup and columns for status + declared attributes
- **Given** the list has custom attributes
  **When** I export
  **Then** each attribute is its own column
- **Given** a large list
  **When** I export
  **Then** the export streams/completes without timing out

## Notes
Same data path as the management `GET .../signups` backfill export.
