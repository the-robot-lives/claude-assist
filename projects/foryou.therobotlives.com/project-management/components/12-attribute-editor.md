# 12: AttributeEditor

| Field | Value |
|-------|-------|
| ID | CMP-12 |
| Category | Domain-Specific |
| Used In | SCR-09 |

## Description
The composite editor for declaring a List's typed attributes: per-attribute rows,
a type picker, an options editor for select types, validation-rule fields, and
drag reordering — implementing the no-migration attribute model.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Row | A single attribute definition |
| Panel | Full editor managing all attributes |

## Props / Configuration
- `attributes` — array — declarations (type, label, required, options, validation, order)
- `onAdd` / `onChange` / `onReorder` / `onDeprecate`
- `types` — supported attribute types

## Interactions
- Add attributes of each type; edit validation and options
- Drag to reorder; deprecate/hide while preserving stored values
- Feeds DynamicForm (CMP-02) preview
