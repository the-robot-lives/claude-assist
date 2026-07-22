# 11: AppShell (Navbar / Sidebar Layout)

| Field | Value |
|-------|-------|
| ID | CMP-11 |
| Category | Navigation & Layout |
| Used In | SCR-02, SCR-17 |

## Description
The application chrome: top navbar and (for admin) sidebar, hosting the switchers
and primary navigation. The navbar variant no longer includes the cookie-settings
button; the admin variant adds a guarded sidebar.

## Size Variants

| Variant | Use Case |
|---------|---------|
| App | Standard authed layout (navbar, no cookie button) |
| Admin | Adds guarded sidebar for the admin console |

## Props / Configuration
- `variant` — app | admin
- `nav` — navigation items
- `user` — current user context
- `guard` — admin/role gate for the admin variant

## Interactions
- Hosts EntitySwitcher (CMP-08); renders nav
- Admin variant enforces the RequireAdmin guard (fixed)
- Cookie consent still available via banner/provider (button removed)
