---
id: US-076
title: "Search and filter signups"
slug: search-filter-signups
personas: [P-003, P-004]
epic: "Admin Console"
priority: should-have
complexity: medium
tags: [admin, signups, search, filter]
---

# US-076: Search and filter signups

## User Story

**As a** site owner/admin
**I want to** search and filter a list's signups
**So that** I can find specific people or segments

## Acceptance Criteria

- **Given** the signups table
  **When** I search by email or an attribute value
  **Then** the table shows matching signups
- **Given** I filter by status (pending/subscribed/unsubscribed/bounced)
  **When** I apply it
  **Then** only signups in that status are shown
- **Given** filters are applied
  **When** I export (US-078)
  **Then** the export respects the active filters

## Notes
