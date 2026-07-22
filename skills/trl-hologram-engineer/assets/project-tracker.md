# Hologram Engineer — Project Tracker

Use this tracker to manage a Hologram build, migration, or audit engagement. Copy it into the project workspace and keep it updated as work progresses.

## Engagement Metadata

- **Project**: {app / feature name}
- **Mode**: New build / Feature add / Migration / UX audit / Debug
- **Hologram version**: {mix.exs version}
- **Elixir / OTP**: {versions}
- **Target date**: {date}
- **Status**: Discovery / Architecture / Build / UX / Validation / Ship

## Page & Component Inventory

| Route / Component | Type (page / stateful / stateless / layout) | State shape | Actions | Commands | Status |
|-------------------|---------------------------------------------|-------------|---------|----------|--------|
| — | — | — | — | — | ☐ |

## Client/Server Boundary Map

| Interaction | Runs where (action=client / command=server) | Data crossing the wire | Notes |
|-------------|---------------------------------------------|------------------------|-------|
| — | — | — | — |

## UX Checklist

| Concern | Status | Notes |
|---------|--------|-------|
| Semantic HTML / landmarks | ☐ | — |
| Keyboard navigation | ☐ | — |
| Focus management on client transitions | ☐ | — |
| ARIA for dynamic/live regions | ☐ | — |
| Loading / pending / error states | ☐ | — |
| Optimistic vs. authoritative state | ☐ | — |
| Responsive layout | ☐ | — |
| Color contrast / theming | ☐ | — |
| No-JS / progressive enhancement fallback | ☐ | — |

## Quality Gate

| Check | Status | Notes |
|-------|--------|-------|
| `mix compile` clean (no transpile warnings) | ☐ | — |
| Only transpilable Elixir in client code paths | ☐ | — |
| Tests pass (page/component/e2e) | ☐ | — |
| Build artifacts generated | ☐ | — |
| Deploy smoke test | ☐ | — |

## Open Questions / Risks

| Item | Owner | Resolution |
|------|-------|------------|
| — | — | — |

## Audit Log

| Date | Change | By |
|------|--------|----|
| — | — | — |
