# 13: PreferenceControls

| Field | Value |
|-------|-------|
| ID | CMP-13 |
| Category | Domain-Specific |
| Used In | SCR-08, SCR-15 |

## Description
The grouped contact-preference controls: frequency select, channel toggles
(email active; sms/push/webhook/mail stored-only), timezone-aware quiet-period
editor, pause control, and reset-to-default. Used by subscribers and by editors
setting list defaults.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Subscriber | Per-subscription overrides |
| List default | Editor-set defaults + available channels |

## Props / Configuration
- `frequency` — immediate/daily/weekly/monthly
- `channels` — enabled set + which are offered
- `quietPeriods` — windows + timezone
- `pauseUntil` — optional snooze date
- `mode` — subscriber | list-default
- `onChange` / `onReset`

## Interactions
- Edit frequency/channels/periods/pause; override then reset defaults
- Non-email channels selectable but flagged deferred; fully accessible
