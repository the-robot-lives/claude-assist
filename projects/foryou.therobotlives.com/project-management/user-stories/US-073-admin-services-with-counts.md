---
id: US-073
title: "List Services with signup counts"
slug: admin-services-with-counts
personas: [P-003]
epic: "Admin Console"
priority: must-have
complexity: medium
tags: [admin, services, counts]
---

# US-073: List Services with signup counts

## User Story

**As a** site owner/admin
**I want to** see all my Services with their aggregate signup counts
**So that** I can compare activity across sites

## Acceptance Criteria

- **Given** I open the Services section
  **When** it loads
  **Then** I see each Service with total signups and list count
- **Given** I select a Service
  **When** I drill in
  **Then** I see its lists with per-list counts (US-074)
- **Given** I lack access to a Service
  **When** the list renders
  **Then** it is not shown to me

## Notes
