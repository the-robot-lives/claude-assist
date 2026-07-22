# Machine / Environment Profile Card

| Field | Value |
|-------|-------|
| **ID** | `machine-environment-profile-card` |
| **Category** | Data Display |
| **Used In** | 01-Query & Answer, 11-Setup Wizard, 13-Settings & Preferences |

## Description

The detected (and user-confirmable) machine profile — OS, installed tools, versions — used both during onboarding and as ambient context that keeps `/query` answers grounded in the user's real environment rather than generic assumptions.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | `macOS 15 · zsh · node 22` |
| **Compact** | Card with OS/shell/key-tool versions |
| **Expanded** | Full detected-tool table with confirm/edit per row |

## Props / Configuration

- `os`, `shell`
- `tools` — array of `{name, version, detected: boolean}`

## Interactions

- During setup, each row is individually confirmable/editable before being written to `machine-profile.yaml`.
