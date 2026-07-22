# 02: App Home & Orgless Empty State

| Field | Value |
|-------|-------|
| ID | SCR-02 |
| Type | dashboard |
| Category | Onboarding & Auth |
| User Stories | US-005, US-007, US-011 |

## Description
The authenticated landing at `/app`. Shows the app shell (navbar without the
removed cookie-settings button) and, for users with no organization, an empty
state with a create-org call to action.

## Key Components
- AppShell — navbar + layout (cookie-settings button removed; banner/provider kept)
- OrgSwitcher — switch active org; "+ New org" entry
- EmptyState — orgless CTA prompting org creation
- Button — primary "Create organization" CTA

## Interactions
- Switch active organization; open create-org flow
- Orgless CTA shown only when the user has zero orgs

## Navigation
- **From:** Authentication (SCR-01)
- **To:** Create Organization (SCR-03); Services List (SCR-05)
