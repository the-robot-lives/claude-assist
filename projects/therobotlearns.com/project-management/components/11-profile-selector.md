# Profile Selector

| Field | Value |
|-------|-------|
| **ID** | `profile-selector` |
| **Category** | Navigation & Layout |
| **Used In** | 11-Setup Wizard, 12-Profile Manager |

## Description

Lists and switches between named profiles (e.g. "work", "personal-learning"), each carrying its own expertise levels, learning style, and KB path.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | Current profile name only |
| **Compact** | Dropdown/list of all profiles with an active marker |
| **Expanded** | Profile list with per-profile summary (domain count, KB size, last used) |

## Props / Configuration

- `profiles` — array of `{name, kb_path, last_used_at}`
- `active`

## Interactions

- Selecting a profile switches context immediately; a "new profile" action re-enters the Setup Wizard scoped to a new name.
