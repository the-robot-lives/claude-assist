# 06: StatTile

| Field | Value |
|-------|-------|
| ID | CMP-06 |
| Category | Data Display |
| Used In | SCR-06, SCR-17, SCR-18 |

## Description
A compact metric tile showing a single count or KPI (signups, lists, activity)
with an optional label and trend, used across overview and admin dashboards.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Default | Standard dashboard metric |
| Compact | Inline within a card row |
| Large | Hero metric on a dashboard |

## Props / Configuration
- `label` — string
- `value` — number/string
- `trend` — optional delta indicator
- `icon` — optional

## Interactions
- Static display; optional click to drill into the underlying list
- Accessible number formatting and labeling
