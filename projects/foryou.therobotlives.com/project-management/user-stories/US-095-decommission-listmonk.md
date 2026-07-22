---
id: US-095
title: "Decommission listmonk after cutover"
slug: decommission-listmonk
personas: [P-003]
epic: "listmonk Migration"
priority: must-have
complexity: medium
tags: [migration, decommission, cleanup, terraform]
---

# US-095: Decommission listmonk after cutover

## User Story

**As a** site owner
**I want to** remove listmonk once every site is migrated
**So that** we no longer run a redundant, replaced service

## Acceptance Criteria

- **Given** all sites are cut over and backfilled (US-094 shows ready)
  **When** I decommission listmonk
  **Then** its Terraform, TimescaleDB db/role, and DNS are removed
- **Given** decommission is planned
  **When** I run it
  **Then** a final export/backup is retained before teardown
- **Given** listmonk is removed
  **When** I check the portfolio
  **Then** no site references or depends on it

## Notes
Removes `terraform/kubernetes/platform/marketing/listmonk.tf` and related
resources. Must be last (plan Chunk H / M5).
