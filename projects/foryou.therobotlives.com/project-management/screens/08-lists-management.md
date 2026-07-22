# 08: Lists Management

| Field | Value |
|-------|-------|
| ID | SCR-08 |
| Type | primary |
| Category | Lists & Attributes |
| User Stories | US-023, US-024, US-025 |

## Description
Within a Service: create Lists, configure a List's settings (slug, opt-in mode,
preference defaults), and archive/restore Lists.

## Key Components
- ListCard — per-List row with counts and status
- FormField — create/edit list fields
- OptInModeToggle — single vs double opt-in
- PreferenceDefaultsFields — default frequency/channels/periods
- Button — "New List" / archive / restore

## Interactions
- Create/edit/archive a List; set opt-in mode and preference defaults
- Slug validation; open a List's attribute editor

## Navigation
- **From:** Service Overview (SCR-06)
- **To:** List Attribute Editor (SCR-09); List Form Preview (SCR-10)
