# timely.noizu.com backend

Phoenix API + **Hologram** isomorphic UI. Two-container stack (backend, nginx) with Postgres/Redis on a shared Docker network.

Hydrated from `components/hologram-start-app` (the Hologram sibling of `components/start-app`, Next.js frontend). It reuses the same backend domain model (auth, orgs, PBAC, media, SSO) and the **@noizu/styleguide** design system (YAML themes → CSS), but renders the UI with Hologram pages/components instead of React.

## Architecture

| Layer | Choice |
|-------|--------|
| UI | Hologram 0.10 (`~HOLO`, client actions, server commands) |
| Design system | Style-guide CSS tokens + semantic classes (`btn`, `card`, `sg-*`) |
| API | Phoenix JSON at `/api/v1/*` (same as start-app) |
| Auth UI | Session-backed Hologram commands + Guardian JWT for the API |
| Proxy | Nginx → single backend |

```
Browser ──► nginx ──► Phoenix
                       ├── Hologram.Router  (pages, commands)
                       └── TimelyWeb.Router (JSON API, SSO)
```

## Quick Start

```bash
make init          # Generate .env files with secrets
make build         # Build backend + nginx images
make run           # Start containers (nginx on :8080)
```

### Dev (hot reload)

```bash
make run-dev       # Foreground: mix holo + nginx
make run-dev-d     # Detached
make logs-dev
make stop-dev
```

Dev uses `mix holo` (sets `HOLOGRAM_START=1`) so the Hologram compiler and client runtime are enabled.

### Local backend only

```bash
mix deps.get
export HOLOGRAM_START=1
mix holo
```

## Style guide (canonical Hologram components)

**This app owns the design-system Hologram components and interactive viewer** — not
`components/styleguide/hologram` (that path is retired; `styleguide/app` remains the
optional Node CSS generator).

```
lib/timely_web/hologram/
  components/     # Btn, Card, ColorSwatch, SectionHeader, AppShell, …
  sections/       # ColorPalette, ShellLayouts, YamlConfig, ComponentBrowser, HuiShowcase
  pages/
    style_guide_page.ex      # /styleguide
    tailwind_plus_page.ex    # /styleguide/tailwind-plus
lib/timely/style_guide/
  catalog.ex / theme_data.ex / component_catalog.ex / twp_catalog.ex
themes/theme-*/       # Live YAML (discovered at runtime)
priv/static/themes/   # Prebuilt CSS per theme
priv/static/twp/      # Tailwind Plus demos + registry.json
```

Regenerate CSS when themes change (optional host tooling with `@noizu/styleguide`):

```bash
make regen
```

## Pages (start-app parity)

| Route | Module |
|-------|--------|
| `/` | `HomePage` |
| `/login` | `LoginPage` (email → SSO/password) |
| `/signup` | `SignupPage` |
| `/forgot-password` | `ForgotPasswordPage` (request + verify code + new password) |
| `/app` | `AppHomePage` (auth required) |
| `/app/profile` | `ProfilePage` (profile + change password) |
| `/app/:org_id` | `OrgDashboardPage` |
| `/app/:org_id/members` | `OrgMembersPage` (list / invite / role / remove) |
| `/app/admin/users` | `AdminUsersPage` (list + approve; admin only) |
| `/app/admin/orgs` | `AdminOrgsPage` (list; admin only) |
| `/styleguide` | `StyleGuidePage` (YAML themes, components, shells) |
| `/styleguide/tailwind-plus` | `TailwindPlusPage` |
| `/complete-registration` | `CompleteRegistrationPage` |
| `/pending-approval` | `PendingApprovalPage` |
| `/auth/verify` | Magic link |
| `/auth/verify-email` | Email verification |
| `/auth/sso-callback` | SSO code exchange |
| `/sitemap` | Site map |

JSON API routes from start-app remain under `/api/v1/*`.

### Still not ported (vs React start-app)

- Projects list/detail UI
- Media upload UI
- Browser analytics / OTEL providers
- i18n
- Cypress e2e suite
- Magic-link / OTP **request** buttons on login (verify routes exist)

## Provenance

Hydrated (manually — `utilities/start-app-scaffold` hardcodes `components/start-app` as its
template and can't target this one yet) from `components/hologram-start-app` into
`projects/timely.noizu.com/apps/backend/` with `Starter`/`starter` → `Timely`/`timely`.
The template's `backend/` subdirectory was flattened up so `mix.exs` sits at this directory's
root, alongside `nginx/`, `sandbox/`, `docker-compose*.yaml`, etc. The Helm chart was promoted
to `projects/timely.noizu.com/helm/timely/` per this repo's per-project chart convention.

## Migrations & tests

```bash
make migrate
mix test
```

## Comparison with start-app

| | start-app | hologram-start-app |
|--|-----------|--------------------|
| Frontend | Next.js 15 | Hologram 0.10 |
| Containers | nginx + backend + frontend | nginx + backend |
| UI language | TypeScript/React | Elixir (`~HOLO`) |
| Design system | `@noizu/styleguide` React + CSS | Style-guide CSS + Hologram components |
| Auth UI state | localStorage JWT | Hologram session + Guardian |
| API | `/api/v1/*` | same |
