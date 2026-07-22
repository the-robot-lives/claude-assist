# 22: DetailPanel (Signup / Inquiry)

| Field | Value |
|-------|-------|
| ID | CMP-22 |
| Category | Modals & Overlays |
| Used In | SCR-19, SCR-20 |

## Description
A slide-over/drawer showing the full detail of a selected record: a signup's
attribute values, status history, preferences, and account linkage; or an
inquiry's full content including enhanced fields.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Signup | Attributes, status history, preferences, linkage |
| Inquiry | Full inquiry incl. company/project/budget/timeline |

## Props / Configuration
- `recordType` — signup | inquiry
- `record` — full record data
- `onClose`
- `permissions` — gate on view access

## Interactions
- Open from a DataTable row; focus-trapped; keyboard operable
- Read-focused; respects access control and no-existence-leak boundary
