# 21: MigrationStatusTable

| Field | Value |
|-------|-------|
| ID | CMP-21 |
| Category | Domain-Specific |
| Used In | SCR-22 |

## Description
The per-site migration tracker: each portfolio site with its current stage and
actions to provision, repoint, verify, backfill, and decommission. Includes a
backfill/import results readout (created/updated/skipped).

## Size Variants

| Variant | Use Case |
|---------|---------|
| Overview | All sites with stage badges |
| Site row | One site's actions + import results |

## Props / Configuration
- `sites` — array — per-site stage + counts
- `onProvision` / `onVerify` / `onBackfill` / `onDecommission`
- `importResults` — created/updated/skipped per site

## Interactions
- Trigger stage actions; view dedupe/import results
- Stage shown via StatusBadge (CMP-10); decommission via ConfirmDialog (CMP-18)
