# 06: Service Overview

| Field | Value |
|-------|-------|
| ID | SCR-06 |
| Type | dashboard |
| Category | Services & Branding |
| User Stories | US-015 |

## Description
The landing view for a selected Service: its lists, signup counts, and key
settings, with an empty state when no lists exist yet.

## Key Components
- StatTile — signup/list count metrics
- ListCard — per-List summary with counts
- EmptyState — prompt to create the first List
- Button — "New List" / open settings

## Interactions
- View lists and counts; open a list or Service settings
- Permission-scoped content by role

## Navigation
- **From:** Services List (SCR-05)
- **To:** Lists Management (SCR-08); Service Settings (SCR-07)
