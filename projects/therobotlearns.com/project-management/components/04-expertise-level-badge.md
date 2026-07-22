# Expertise Level Badge

| Field | Value |
|-------|-------|
| **ID** | `expertise-level-badge` |
| **Category** | Data Display |
| **Used In** | 01-Query & Answer, 10-Learning Plan Dashboard, 12-Profile Manager, 13-Settings & Preferences |

## Description

A compact indicator of the user's expertise level in the domain currently relevant, shown next to answers so depth calibration is legible, and editable in settings/profile screens.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | Single badge, e.g. `[advanced]` |
| **Compact** | Badge plus domain name |
| **Expanded** | Editable table of all domains and their levels |

## Props / Configuration

- `domain` — the expertise domain
- `level` — novice \| intermediate \| advanced \| expert
- `editable` — boolean

## Interactions

- In editable contexts, selecting the badge opens a level picker.
