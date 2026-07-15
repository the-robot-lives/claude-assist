# Styleguide — Hologram viewer

**Canonical design-system viewer.** Stack: **Elixir + Hologram + static assets only** (no TypeScript, no Node runtime).

| Layer | What it is |
|-------|------------|
| UI | Hologram pages/components (`lib/**/*.ex`) |
| Theme CSS | Prebuilt CSS in `priv/static/themes/*.css` |
| Theme tokens (docs) | YAML under `themes/theme-*/` (optional reference) |
| Tailwind Plus demos | Static HTML in `priv/static/twp/demos/**` + `registry.json` |

## Quick start

```bash
cd components/styleguide/hologram
mix deps.get
cp .env.example .env   # fill OIDC_* for Authentik SSO
export HOLOGRAM_START=1
mix holo
# → http://localhost:4500/              landing
# → http://localhost:4500/login         Authentik SSO
# → http://localhost:4500/style-guide   design-system viewer
# → http://localhost:4500/style-guide/tailwind-plus
```

### Authentik SSO

Same env names as hologram-start-app. Loaded from process env **or** `hologram/.env`:

Uses the **same Authentik application as hologram-start-app** (`startapp` on **auth.derobot.is**).

| Variable | Value |
|----------|--------|
| `OIDC_ISSUER` | `https://auth.derobot.is/application/o/startapp` |
| `OIDC_CLIENT_ID` / `SECRET` | same as `START_APP_OIDC_*` (Infisical / `.envrc.dc`) |
| `OIDC_REDIRECT_URI` | `http://localhost:4500/auth/oidc/callback` |

Add that redirect URI on the Authentik `startapp` provider if it is not already listed. Restart after changing `.env`.

Health: `GET /health` → `{"status":"ok","viewer":"hologram"}`.

## Layout

```
hologram/
├── lib/                         # Elixir / Hologram only
│   ├── styleguide/              # Catalog, TwpCatalog
│   └── styleguide_web/hologram/ # Layouts, components, pages
├── priv/static/
│   ├── themes/*.css             # Design-system CSS (committed)
│   ├── css/viewer.css           # Viewer chrome
│   └── twp/
│       ├── registry.json        # 686-entry catalog
│       └── demos/**/*.html      # Widget previews (Tailwind CDN in each file)
├── themes/theme-*/              # YAML theme facets (no .ts)
├── mix.exs
└── README.md
```

## Hologram components

Design-system primitives (semantic CSS classes from theme CSS):

| Module | Role |
|--------|------|
| `Components.Btn` | `btn` / `btn-{variant}` |
| `Components.Card` / `CardGrid` | Cards |
| `Components.ButtonRow` | CTA rows |
| `Components.ColorSwatch` / `ColorGrid` | Color samples |
| `Components.TypeSpecimen` | Typography |
| `Components.SpacingScale` | Spacing bars |
| `Components.StatusIndicator` | Status dots |
| `Components.TokenCard` | Token tables |
| `Components.InputField` | Form fields |
| `Components.SectionHeader` | Numbered section titles |
| `Components.StyleCard` | Doc cards |

## Sections

Aligned with the design-system page map (subset implemented in Hologram):

| Group | Sections |
|-------|----------|
| **Visual Foundation** | Typography (subtabs), Color (subtabs), Spacing & Grid (subtabs), Dividers, Glyphs |
| **Structure** | Shell layouts, Content layouts, Navigation |
| **Interaction** | Buttons, Cards, Forms, Status, **HUI Controls** (submenu: checkbox → dialog) |
| **Component Library** | **Component Browser** (category + entry sidebar, live previews) |
| **Reference** | Tokens, Migration, Tailwind Plus |

**HUI Controls** (`Interaction → HUI Controls`): interactive submenu (checkbox, switch, radio, tabs, disclosure, menu, listbox, combobox, popover, dialog, fields) using theme `.hui` CSS + Hologram actions.

**Component Browser** (`Component Library`): filterable categories/entries with live previews of exported primitives.

**Routes**

| Path | Page |
|------|------|
| `/` | Landing (home, login, style guide CTAs) |
| `/login` | Authentik SSO (OIDC) — same flow as hologram-start-app |
| `/app` | **Post-login dashboard** (SSO lands here) |
| `/auth/oidc` | Start Authentik authorization |
| `/auth/oidc/callback` | OIDC callback → session cookies → `/app` |
| `/auth/logout` | Clear SSO session |
| `/style-guide` | Design-system viewer |
| `/style-guide/tailwind-plus` | 686 static HTML widget previews |

**Tailwind Plus** (`/style-guide/tailwind-plus`): demos under `priv/static/twp/`.

## Updating theme CSS

Committed CSS is the source of truth for the viewer. If you regenerate CSS from YAML elsewhere (optional external engine), copy results into `priv/static/themes/`:

```bash
# Example only — not required to run this app:
cp /path/to/generated/*.css priv/static/themes/
```

## What is *not* in this package

- No TypeScript / TSX
- No Node `package.json` or migration scripts
- No Next.js / React runtime

Optional historical/CSS tooling may still live under `components/styleguide/app/` for portfolio Next.js consumers — it is **not** a dependency of this Hologram app.

## Consumer apps

`components/hologram-start-app` vendors a subset of primitives under `StarterWeb.Hologram.Components`. Prefer aligning with modules here.
