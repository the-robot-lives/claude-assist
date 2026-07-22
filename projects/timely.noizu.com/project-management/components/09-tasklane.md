# 09: TaskLane

| Field | Value |
|-------|-------|
| ID | CMP-09 |
| Category | Domain-Specific |
| Used In | SCR-05 |

## Description
Lane-based representation of project, task, idle, and secondary work intervals.

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
