# 03: Create Organization

| Field | Value |
|-------|-------|
| ID | SCR-03 |
| Type | primary |
| Category | Onboarding & Auth |
| User Stories | US-006, US-008 |

## Description
The `/app/orgs/new` form where an orgless user (or a user adding another org)
creates an organization with a slug and name and becomes its owner.

## Key Components
- FormField — name and slug inputs with validation
- InlineAlert — slug-taken / invalid errors
- Button — submit / cancel

## Interactions
- Submit to create org (wired to `api.createOrganization`)
- Inline slug validation; on success switch into the new org
- Reachable from the orgless CTA and the "+ New org" switcher entry

## Navigation
- **From:** App Home orgless CTA (SCR-02); OrgSwitcher "+ New org"
- **To:** Service Overview / Services List after creation (SCR-05/SCR-06)
