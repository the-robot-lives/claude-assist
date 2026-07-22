# 15: SearchFilterBar

| Field | Value |
|-------|-------|
| ID | CMP-15 |
| Category | Input & Forms |
| Used In | SCR-19, SCR-20 |

## Description
A search input plus filter controls (status, attribute values, date) that drive a
DataTable and are respected by exports. Used on the admin signups and inquiries
tables.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Signups | Search email/attributes + status filter |
| Inquiries | Search fields + date/site filters |

## Props / Configuration
- `searchValue` / `onSearch`
- `filters` — available filter defs
- `activeFilters` / `onFilterChange`
- `context` — signups | inquiries

## Interactions
- Debounced search; apply/clear filters
- Active filters feed table + ExportButton (CMP-16)
