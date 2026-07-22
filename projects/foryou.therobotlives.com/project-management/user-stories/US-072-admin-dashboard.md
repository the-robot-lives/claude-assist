---
id: US-072
title: "See an admin dashboard overview"
slug: admin-dashboard
personas: [P-003]
epic: "Admin Console"
priority: must-have
complexity: medium
tags: [admin, dashboard, overview, metrics]
---

# US-072: See an admin dashboard overview

## User Story

**As a** site owner/admin
**I want to** see an overview of signups and lists across my Services
**So that** I can gauge activity at a glance

## Acceptance Criteria

- **Given** I open the admin console
  **When** the dashboard loads
  **Then** I see summary metrics (total signups, lists, recent activity) for Services I can access
- **Given** I have access to several Services
  **When** the dashboard renders
  **Then** metrics are scoped to those Services only
- **Given** there is no activity yet
  **When** the dashboard loads
  **Then** I see a clear zero/empty state

## Notes
