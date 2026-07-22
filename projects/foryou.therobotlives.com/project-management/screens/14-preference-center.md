# 14: Preference Center Dashboard

| Field | Value |
|-------|-------|
| ID | SCR-14 |
| Type | dashboard |
| Category | Preference Center |
| User Stories | US-050, US-061, US-062, US-064, US-066, US-069, US-070 |

## Description
The authenticated `/app/me` dashboard where one account manages subscriptions
across all portfolio sites, grouped by Service, with unsubscribe/resume actions
and an empty state. Accessible and low-bandwidth friendly.

## Key Components
- SubscriptionGroup — subscriptions grouped by Service/site
- SubscriptionRow — one subscription with status + actions
- Button — unsubscribe / re-subscribe / resume / manage
- EmptyState — no-subscriptions guidance
- ServiceSwitcher — cross-site context (reused)

## Interactions
- View all subscriptions cross-site; group by Service
- Unsubscribe / re-subscribe / resume; open per-subscription preferences
- Announced updates; empty state when nothing yet

## Navigation
- **From:** Authentication (SCR-01); opt-in/unsubscribe pages (SCR-13)
- **To:** Contact Preference Editor (SCR-15); My Inquiries & Data (SCR-16)
