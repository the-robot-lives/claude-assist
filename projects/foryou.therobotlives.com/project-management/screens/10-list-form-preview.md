# 10: List Form Preview

| Field | Value |
|-------|-------|
| ID | SCR-10 |
| Type | modal |
| Category | Lists & Attributes |
| User Stories | US-035 |

## Description
A preview of the public signup form generated from a List's declared attributes,
including field types, required markers, and test validation without creating a
real signup.

## Key Components
- DynamicForm — attribute-driven form renderer
- FormField — per-type field renderers
- Button — "test submit" (no-op) / close

## Interactions
- Render current attributes; reflect reorders/edits on refresh
- Test-submit validates without persisting

## Navigation
- **From:** List Attribute Editor (SCR-09); Lists Management (SCR-08)
- **To:** back to editor
