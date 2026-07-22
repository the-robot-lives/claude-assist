# 05: Services List & Switcher

| Field | Value |
|-------|-------|
| ID | SCR-05 |
| Type | dashboard |
| Category | Services & Branding |
| User Stories | US-013, US-020, US-021 |

## Description
Lists all Services within the active organization, lets the user create a new
Service, switch between Services, and archive/restore one.

## Key Components
- ServiceCard — per-Service summary tile with quick open
- ServiceSwitcher — switch active Service context
- EmptyState — prompt to create the first Service
- Button — "New Service" / archive / restore

## Interactions
- Create a Service (name/slug); open or switch a Service
- Archive/restore a Service; empty state when none exist

## Navigation
- **From:** App Home (SCR-02)
- **To:** Service Overview (SCR-06); Service Settings (SCR-07)
