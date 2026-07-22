# 14: SubscriptionList

| Field | Value |
|-------|-------|
| ID | CMP-14 |
| Category | Domain-Specific |
| Used In | SCR-14 |

## Description
The cross-site subscription list: subscriptions grouped by Service with per-row
status and actions (manage/unsubscribe/resume). The heart of the preference
center's unified view.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Group | A Service's grouped subscriptions |
| Row | A single subscription with actions |

## Props / Configuration
- `groups` — subscriptions grouped by Service
- `onUnsubscribe` / `onResubscribe` / `onResume` / `onManage`
- `emptyState` — EmptyState config when none

## Interactions
- Group by Service; per-row and per-group actions
- Opens PreferenceControls (CMP-13); announced updates; accessible
