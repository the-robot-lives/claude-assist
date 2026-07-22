---
id: US-094
title: "Track migration status across all sites"
slug: migration-status-tracking
personas: [P-003]
epic: "listmonk Migration"
priority: should-have
complexity: medium
tags: [migration, status, tracking, dashboard]
---

# US-094: Track migration status across all sites

## User Story

**As a** site owner
**I want to** track each site's migration state
**So that** I know what's provisioned, repointed, verified, and backfilled

## Acceptance Criteria

- **Given** the migration is in progress
  **When** I open a migration status view
  **Then** I see each site's stage (provisioned / repointed / verified / backfilled)
- **Given** a site completes a stage
  **When** its state updates
  **Then** the tracker reflects it
- **Given** all sites are backfilled
  **When** I view the tracker
  **Then** it shows the portfolio is ready to decommission listmonk (US-095)

## Notes
