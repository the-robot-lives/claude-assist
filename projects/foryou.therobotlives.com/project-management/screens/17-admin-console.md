# 17: Admin Console (Layout & Dashboard)

| Field | Value |
|-------|-------|
| ID | SCR-17 |
| Type | dashboard |
| Category | Admin Console |
| User Stories | US-071, US-072, US-099 |

## Description
The guarded `/app/admin` shell: sidebar navigation and an overview dashboard with
summary metrics and operational/observability signals, accessible only to
admins/owners.

## Key Components
- AdminShell — sidebar + guarded layout
- StatTile — signup/list/activity metrics
- MetricsPanel — signup volume, rate-limit hits, abuse signals
- EmptyState — zero-activity state

## Interactions
- Navigate admin sections; view scoped metrics
- Access denied + redirect for non-admins (RequireAdmin fixed)

## Navigation
- **From:** App Home (SCR-02) for admins
- **To:** Admin Services & Lists (SCR-18); Admin Signups (SCR-19); Admin Inquiries (SCR-20)
