# hologram-start-app

Phoenix API + **Hologram** isomorphic UI scaffold. Two-container stack (backend, nginx) with Postgres/Redis on a shared Docker network.

This is the Hologram sibling of [`components/start-app`](../start-app) (Next.js frontend). It reuses the same backend domain model (auth, orgs, PBAC, media, SSO) and the **@noizu/styleguide** design system (YAML themes → CSS), but renders the UI with Hologram pages/components instead of React.

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
                       └── StarterWeb.Router (JSON API, SSO)
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
cd backend
mix deps.get
export HOLOGRAM_START=1
mix holo
```

## Style guide components

Canonical StyleGuide* Hologram ports live in **`components/styleguide/hologram`** (viewer + component catalog).  
This scaffold vendors a subset for the app shell under:

```
backend/lib/starter_web/hologram/components/
  btn.ex          # StyleGuideBtn → btn / btn-{variant}
  card.ex         # StyleGuideCard
  card_grid.ex
  button_row.ex
  field.ex        # sg-field form chrome
  navbar.ex       # sg-navbar chrome
  cookie_consent.ex
```

Prefer aligning names with `StyleguideWeb.Hologram.Components.*` when extending.

Theme YAML (from styleguide engine) is in `assets/theme-style-guide/`. Pre-generated CSS is shipped at:

- `backend/priv/static/themes/design-system.generated.css`
- `backend/priv/static/themes/style-guide.css`
- `backend/priv/static/css/app.css` (layout helpers)

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
| `/complete-registration` | `CompleteRegistrationPage` |
| `/pending-approval` | `PendingApprovalPage` |
| `/auth/verify` | Magic link |
| `/auth/verify-email` | Email verification |
| `/auth/sso-callback` | SSO code exchange |
| `/sitemap` | Site map |

JSON API routes from start-app remain under `/api/v1/*`.

### Still not ported (vs React start-app)

- In-app `/styleguide` multi-theme viewer (use `components/styleguide/hologram`)
- Projects list/detail UI
- Media upload UI
- Browser analytics / OTEL providers
- i18n
- Cypress e2e suite
- Magic-link / OTP **request** buttons on login (verify routes exist)

## Scaffolding into a project

Same hydration pattern as start-app (rename `Starter` → your module). Prefer the existing `start-app-scaffold` flow once this component is registered, or copy/rsync and sed-rename as with start-app.

## Migrations & tests

```bash
make migrate
cd backend && mix test
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
