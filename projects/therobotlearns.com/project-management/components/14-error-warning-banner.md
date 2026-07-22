# Error / Warning Banner

| Field | Value |
|-------|-------|
| **ID** | `error-warning-banner` |
| **Category** | Feedback & Indicators |
| **Used In** | 11-Setup Wizard, 14-KB Maintenance Console, 19-Error & Recovery Notices |

## Description

An inline terminal block for anything from a soft warning (a missing optional prerequisite) to a hard error (corrupted file, unreachable backend), always paired with a concrete next step.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | Single-line `⚠`/`✗`-prefixed message |
| **Compact** | Message plus one-line remediation |
| **Expanded** | Full explanation, affected file(s), and numbered resolution steps |

## Props / Configuration

- `severity` — warning \| error
- `message`, `remediation`
- `affected` — optional file/path list

## Interactions

- Where remediation is automatable, the banner offers a direct "fix it now" prompt (e.g. quarantine and continue, or launch the missing-prerequisite installer).
