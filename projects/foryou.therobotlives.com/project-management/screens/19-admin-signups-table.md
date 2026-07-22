# 19: Admin Signups Table & Detail

| Field | Value |
|-------|-------|
| ID | SCR-19 |
| Type | primary |
| Category | Admin Console |
| User Stories | US-075, US-076, US-077, US-078, US-079, US-085 |

## Description
The core admin surface: a signups table for a List with columns derived from its
declared attributes, plus search/filter/sort/paginate, CSV export, and a single
signup detail view. Also surfaces inquiries modeled as contact-list signups.

## Key Components
- SignupsDataTable — attribute-derived columns, sort/paginate
- SearchFilterBar — search + status/attribute filters
- ExportButton — CSV export honoring filters
- SignupDetailPanel — full attribute values, status history, preferences
- Badge — status indicator

## Interactions
- View/search/filter/sort/paginate signups; export CSV
- Open a signup's detail; view account linkage; contact-list signups appear here

## Navigation
- **From:** Admin Services & Lists (SCR-18)
- **To:** signup detail panel
