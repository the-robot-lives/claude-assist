# Confirmation Prompt

| Field | Value |
|-------|-------|
| **ID** | `confirmation-prompt` |
| **Category** | Modals & Overlays |
| **Used In** | 11-Setup Wizard, 12-Profile Manager, 14-KB Maintenance Console, 15-Backup & Restore, 20-Integrations |

## Description

A Y/n (or typed-confirmation) gate in front of any destructive or hard-to-reverse action: uninstall, restore-from-backup, re-run setup, schema migration, or enabling an outward integration.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | `Proceed? [y/N]` |
| **Compact** | One-line consequence summary plus y/N |
| **Expanded** | Full consequence explanation, requiring a typed confirmation phrase for the most destructive actions (e.g. restore-overwrite) |

## Props / Configuration

- `action`, `consequence`
- `requiresTypedConfirmation` — boolean

## Interactions

- Defaults to the non-destructive choice; pressing Enter alone never confirms a destructive action.
