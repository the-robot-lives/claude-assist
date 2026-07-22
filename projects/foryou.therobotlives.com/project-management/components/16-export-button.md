# 16: ExportButton

| Field | Value |
|-------|-------|
| ID | CMP-16 |
| Category | Input & Forms |
| Used In | SCR-16, SCR-19 |

## Description
An action that exports the current dataset (signups, or the user's own data) to a
downloadable file, honoring active filters and streaming large sets.

## Size Variants

| Variant | Use Case |
|---------|---------|
| CSV | Admin signups export |
| Data package | User self-service data export (GDPR) |

## Props / Configuration
- `format` — csv | json
- `scope` — filtered admin data | my-data
- `filters` — active filters to honor
- `onExport` — triggers generation/download

## Interactions
- Trigger export; progress/loading state; download on completion
- Rate-limited for self-service exports
