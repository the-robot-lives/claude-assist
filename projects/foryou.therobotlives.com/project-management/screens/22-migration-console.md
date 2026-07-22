# 22: Migration Console

| Field | Value |
|-------|-------|
| ID | SCR-22 |
| Type | dashboard |
| Category | listmonk Migration |
| User Stories | US-036, US-089, US-090, US-091, US-092, US-093, US-094, US-095, US-098 |

## Description
An operator surface to run and track the per-site listmonk→foryou migration:
provision lists (via TF), repoint forms, verify cutover, backfill subscribers,
track status across all sites, and decommission listmonk when complete.

## Key Components
- MigrationStatusTable — per-site stage (provisioned/repointed/verified/backfilled)
- StageBadge — stage indicator per site
- ImportPanel — backfill/import with dedupe results (created/updated/skipped)
- Button — trigger provision / verify / backfill / decommission
- ConfirmDialog — decommission confirmation

## Interactions
- Provision a List per site (TF); repoint + verify; run one-time backfill (dedupe)
- Track all sites' migration status; decommission listmonk when all done

## Navigation
- **From:** Admin Console (SCR-17)
- **To:** Admin Signups Table (SCR-19) to verify imported records
