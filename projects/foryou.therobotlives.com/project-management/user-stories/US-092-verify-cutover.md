---
id: US-092
title: "Verify a site no longer sends to listmonk"
slug: verify-cutover
personas: [P-003]
epic: "listmonk Migration"
priority: must-have
complexity: low
tags: [migration, verification, cutover]
---

# US-092: Verify a site no longer sends to listmonk

## User Story

**As a** site owner
**I want to** confirm a repointed site sends no new signups to listmonk
**So that** it is safe to backfill and eventually decommission

## Acceptance Criteria

- **Given** a site has been repointed
  **When** I submit test and monitor real signups
  **Then** they land in foryou and none arrive in listmonk
- **Given** verification passes
  **When** I mark the site cut over
  **Then** it becomes eligible for backfill (US-093)
- **Given** verification fails
  **When** signups still reach listmonk
  **Then** the site is flagged and not marked cut over

## Notes
Verification must precede backfill to avoid duplicates.
