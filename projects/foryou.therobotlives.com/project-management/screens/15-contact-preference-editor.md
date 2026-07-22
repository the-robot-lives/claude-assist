# 15: Contact Preference Editor

| Field | Value |
|-------|-------|
| ID | SCR-15 |
| Type | modal |
| Category | Contact Preferences |
| User Stories | US-051, US-052, US-053, US-054, US-055, US-056, US-057, US-058, US-059, US-060, US-063 |

## Description
The controls for editing a subscription's contact preferences: frequency,
channels, quiet periods, pause, and override/reset of list defaults. Non-email
channels can be selected (stored) though delivery on them is deferred.

## Key Components
- FrequencySelect — immediate/daily/weekly/monthly
- ChannelToggles — email (active) + sms/push/webhook/mail (stored, deferred)
- QuietPeriodEditor — timezone-aware windows
- PauseControl — snooze until a date
- ResetToDefaultButton — clear overrides
- InlineAlert — announced save state

## Interactions
- Set frequency/channels/periods; pause; override then optionally reset defaults
- Editor sets per-list defaults; subscriber overrides them
- Fully keyboard/screen-reader operable

## Navigation
- **From:** Preference Center (SCR-14); Lists Management (SCR-08, defaults side)
- **To:** back to Preference Center
