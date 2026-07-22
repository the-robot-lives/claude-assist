# 05: DataTable

| Field | Value |
|-------|-------|
| ID | CMP-05 |
| Category | Tables & Lists |
| Used In | SCR-04, SCR-18, SCR-19, SCR-20, SCR-22 |

## Description
The reusable data table: sortable, filterable, paginated rows with configurable
columns. Backs members, admin services/lists, signups, inquiries, and migration
status tables.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Compact | Dense admin lists |
| Default | Standard tables |
| Expandable | Rows that open a detail panel |

## Props / Configuration
- `columns` — array — column defs (some derived from list attributes)
- `rows` — array — data
- `sort` / `onSort` — sort state
- `page` / `onPage` — pagination
- `filters` — active filter set
- `onRowOpen` — open detail

## Interactions
- Sort by column; paginate; filter; open a row's detail
- Attribute-derived columns for signups; keyboard navigable
- Export respects active filters (via ExportButton, CMP-16)
