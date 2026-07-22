# Theme Picker

| Field | Value |
|-------|-------|
| **ID** | `theme-picker` |
| **Category** | Input & Forms |
| **Used In** | 07-Quiz SPA, 13-Settings & Preferences |

## Description

Lets the user choose among the four design-system directions (Scholar, Atlas, Spark, Deep Focus) for the Quiz SPA, with the choice persisted as a default preference.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | Four-swatch row |
| **Compact** | Swatch row plus selected theme name |
| **Expanded** | Live preview panel per theme |

## Props / Configuration

- `options` — [scholar, atlas, spark, deep-focus]
- `selected`
- `persistAsDefault` — boolean

## Interactions

- Selecting a swatch re-themes the SPA immediately; a checkbox persists it to `local-preference.yaml`.
