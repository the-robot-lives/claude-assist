---
id: US-089
title: "Migrate every site's listmonk signups to foryou"
slug: migrate-all-listmonk-signups
personas: [P-003]
epic: "listmonk Migration"
priority: must-have
complexity: high
tags: [migration, listmonk, cutover, backfill, item-3]
---

# US-089: Migrate every site's listmonk signups to foryou

## User Story

**As a** site owner
**I want to** move every portfolio site's signups from listmonk to foryou
**So that** foryou becomes the single canonical signup platform

## Acceptance Criteria

- **Given** the portfolio sites currently POST to listmonk
  **When** the migration completes for a site
  **Then** new signups land in foryou and historical subscribers are backfilled
- **Given** all sites are migrated
  **When** I audit signup destinations
  **Then** no site still writes to listmonk
- **Given** the migration is per-site
  **When** one site is cut over
  **Then** the others are unaffected until their own cutover

## Notes
MANDATORY — plan item 3 (umbrella). Sites: therobotlives.com, codefre.sh (x2),
gotta.cc, aifighter.com, noizu.com, robots-unite.com, jailbreakingsite.com,
noizurpg.com, iotgo.io. Executes via US-090–US-093 per site, then US-095.
