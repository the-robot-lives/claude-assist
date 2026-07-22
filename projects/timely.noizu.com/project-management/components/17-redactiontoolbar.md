# 17: RedactionToolbar

| Field | Value |
|-------|-------|
| ID | CMP-17 |
| Category | Input & Forms |
| Used In | SCR-07, SCR-17 |

## Description
Controls for blur, delete, exclude app, and exclude domain actions.

## Size Variants

| Variant | Use Case |
|---------|----------|
| Default | Primary use in full-width dashboard or review layouts. |
| Compact | Dense timeline, sidebar, drawer, or mobile layout. |
| Large | Focused review, modal, or report-building contexts. |

## Props / Configuration
- `id` - string - Stable component or record id.
- `state` - enum - Visual and interaction state.
- `density` - enum - Comfortable, compact, or review-dense layout mode.
- `readonly` - boolean - Disables mutation controls for audit, export, or viewer roles.

## Interactions
- Provides visible focus state and keyboard reachable controls.
- Uses short motion only to communicate state changes; respects reduced-motion preferences.
- Keeps labels and critical values visible in compact layouts.
