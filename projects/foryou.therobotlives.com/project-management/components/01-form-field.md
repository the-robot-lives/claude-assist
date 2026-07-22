# 01: FormField (Typed Field Renderer)

| Field | Value |
|-------|-------|
| ID | CMP-01 |
| Category | Input & Forms |
| Used In | SCR-01, SCR-03, SCR-04, SCR-07, SCR-08, SCR-10, SCR-11, SCR-12, SCR-15, SCR-21 |

## Description
The single field renderer that maps a List Attribute's type to the correct
accessible control. One component, one variant per attribute type — the backbone
of every dynamic and static form in the product.

## Size Variants

| Variant | Use Case |
|---------|---------|
| string | Free-text single-line input |
| email | Email input with email validation |
| int / float | Numeric input with numeric validation + bounds |
| date | Date picker with date validation |
| guid | Token/identifier input with format validation |
| select | Single-choice control from fixed options |
| multi-select | Multi-choice control from fixed options |

## Props / Configuration
- `type` — attribute type — selects the control variant
- `label` — string — visible + programmatic label
- `required` — boolean — required marker + validation
- `options` — array — for select / multi-select
- `validation` — object — pattern, min/max, length
- `value` / `onChange` — controlled value binding
- `error` — string — field-level error message

## Interactions
- Focus/hover/active states; keyboard operable
- Field-level errors announced (not color-only)
- Client validation mirrored by authoritative server validation
