---
id: US-074
title: "List Lists per Service with signup counts"
slug: admin-lists-with-counts
personas: [P-003, P-004]
epic: "Admin Console"
priority: must-have
complexity: medium
tags: [admin, lists, counts]
---

# US-074: List Lists per Service with signup counts

## User Story

**As a** site owner/admin or editor
**I want to** see the lists within a Service and each list's signup count
**So that** I can find and open the list I care about

## Acceptance Criteria

- **Given** I open a Service in the admin console
  **When** its lists load
  **Then** I see each list with signup count and opt-in mode
- **Given** I select a list
  **When** I open it
  **Then** I see its signups table (US-075)
- **Given** a list has zero signups
  **When** it renders
  **Then** it shows a zero count, not a missing row

## Notes
