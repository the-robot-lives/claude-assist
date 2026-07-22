# 02: DynamicForm (Attribute-Driven Form)

| Field | Value |
|-------|-------|
| ID | CMP-02 |
| Category | Input & Forms |
| Used In | SCR-10, SCR-11, SCR-12 |

## Description
Renders a full signup form from a List's declared attributes, composing FormField
(CMP-01) per attribute in order. Shared by the hosted signup page, the embeddable
widget, and the form preview so all three stay identical.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Hosted | Full-page public signup form |
| Widget | Embedded (script/iframe) rendering on external sites |
| Preview | Editor preview with non-persisting test submit |

## Props / Configuration
- `attributes` — array — declared attribute definitions (ordered)
- `listRef` — service/list identifiers for submission
- `theme` — object — branding/theme options
- `onSubmit` — submit handler (POST to public endpoint)
- `mode` — hosted | widget | preview

## Interactions
- Renders fields dynamically; re-renders on attribute changes
- Client validation; submits to rate-limited public endpoint
- Generic success handling; accessible + low-bandwidth
