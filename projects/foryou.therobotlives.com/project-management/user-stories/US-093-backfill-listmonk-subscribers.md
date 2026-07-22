---
id: US-093
title: "Backfill listmonk subscribers into foryou"
slug: backfill-listmonk-subscribers
personas: [P-003]
epic: "listmonk Migration"
priority: must-have
complexity: high
tags: [migration, backfill, import, dedupe]
---

# US-093: Backfill listmonk subscribers into foryou

## User Story

**As a** site owner
**I want to** import a site's existing listmonk subscribers into foryou
**So that** historical subscribers are preserved after cutover

## Acceptance Criteria

- **Given** a cut-over site's exported listmonk subscribers
  **When** I import them via `POST .../signups/import`
  **Then** they are created in the foryou List with appropriate status
- **Given** an imported email already exists in foryou
  **When** the import runs
  **Then** it is deduped by email rather than duplicated
- **Given** the import completes
  **When** I review results
  **Then** I see counts of created, updated, and skipped records

## Notes
Import runs once per site, after verification (US-092). Dedupe by lower(email).
