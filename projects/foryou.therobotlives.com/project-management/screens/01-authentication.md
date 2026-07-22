# 01: Authentication

| Field | Value |
|-------|-------|
| ID | SCR-01 |
| Type | storyboard |
| Category | Onboarding & Auth |
| User Stories | US-001, US-002, US-003, US-004, US-012, US-050 |

## Description
Entry point for signing in and registering. Offers SSO and email login/register,
handles session lifecycle, and triggers reconcile-by-email on successful auth.

## Key Components
- AuthForm — email/password + magic-link fields with validation
- SSOButton — initiates the SSO provider flow
- FormField — labeled, accessible input renderer
- InlineAlert — announced validation/error messaging
- Button — primary submit / logout actions

## Interactions
- Submit login/register; initiate SSO; log out
- Announced validation errors via live region
- Redirect into `/app` on success; reconcile anonymous signups by email

## Navigation
- **From:** public site, unsubscribe/opt-in emails, protected-route redirect
- **To:** App Home (SCR-02); Preference Center (SCR-14)
