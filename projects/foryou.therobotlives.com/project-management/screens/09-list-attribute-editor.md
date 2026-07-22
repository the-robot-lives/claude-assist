# 09: List Attribute Editor

| Field | Value |
|-------|-------|
| ID | SCR-09 |
| Type | primary |
| Category | Lists & Attributes |
| User Stories | US-026, US-027, US-028, US-029, US-030, US-031, US-032, US-033, US-034 |

## Description
Declare and manage a List's typed attributes (email/string/int/float/date/guid/
select/multi-select), required/optional flags, validation, options, ordering, and
deprecation — all without a schema migration.

## Key Components
- AttributeRow — one declared attribute with type + settings
- AttributeTypePicker — choose attribute type
- OptionsEditor — manage select/multi-select options
- ValidationRuleFields — required, min/max, pattern, length
- DragHandle — reorder attributes
- Button — add / deprecate / save

## Interactions
- Add attributes of each type; set required/validation; edit options
- Reorder via drag; deprecate/hide while preserving existing values

## Navigation
- **From:** Lists Management (SCR-08)
- **To:** List Form Preview (SCR-10)
