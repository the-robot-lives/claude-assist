# 09: SummaryCard (Service / List)

| Field | Value |
|-------|-------|
| ID | CMP-09 |
| Category | Cards & Tiles |
| Used In | SCR-05, SCR-06, SCR-08 |

## Description
A summary tile representing a Service or a List with its name, counts, status,
and quick actions. One component with entity-type variants.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Service | Service tile with list + signup counts |
| List | List tile with signup count + opt-in mode |

## Props / Configuration
- `entityType` — service | list
- `name` / `slug`
- `counts` — signups, lists
- `status` — active/archived
- `badges` — opt-in mode, etc.
- `onOpen` — open handler

## Interactions
- Click to open; quick actions (archive/restore)
- Status/opt-in shown via StatusBadge (CMP-10)
