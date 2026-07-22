---
id: US-025
title: "Archive or deactivate a List"
slug: archive-list
personas: [P-004, P-003]
epic: "Lists & Attributes"
priority: could-have
complexity: low
tags: [list, archive, lifecycle]
---

# US-025: Archive or deactivate a List

## User Story

**As a** Service editor
**I want to** archive a List I no longer collect on
**So that** it stops accepting signups while retaining its data

## Acceptance Criteria

- **Given** an active List
  **When** I archive it
  **Then** its public form stops accepting new signups
- **Given** an archived List
  **When** I view its signups
  **Then** the historical data remains accessible read-only
- **Given** an archived List
  **When** I restore it
  **Then** it accepts signups again

## Notes
