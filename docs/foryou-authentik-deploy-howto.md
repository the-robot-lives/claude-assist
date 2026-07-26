# Foryou Authentik Deployment Howto — superseded

> **This document has moved and been corrected.**
> See **[`docs/authentik-oidc-setup.md`](authentik-oidc-setup.md)** — the
> canonical, generalized runbook for wiring Authentik OIDC into any
> `start-app`-derived service.

This page is kept only so existing links resolve. Its contents were
foryou-specific and wrong in several places that will break a bring-up:

| Old claim | Correction |
|---|---|
| Provider pattern copied from the portfolio static sites (public / PKCE) | Must be `client_type: confidential` — the backend does a server-side code exchange |
| API token at `dc get auto authentik_api_token --raw` | That path resolves **empty** — `auto` is a storage layer, not a queryable subject. Use `dc get services design.authentik_api_token --raw` |
| Discovery `200` treated as proof the provider is configured | A `200` only proves an *application* exists — compare the provider `client_id` against the k8s secret explicitly |
| Silent on `infisical-populate-secrets` | Populate writes **empty** for `dc:` keys that don't resolve non-interactively, blanking live DB/secret-key/Guardian credentials |
| Silent on `sso_domains.ex` | Without it, SSO auto-provisions **any** authenticated email as active |
| Silent on migrations | The chart's `migrate` hook runs Ecto (`Release.migrate()`); these schemas are **Liquibase** — it creates nothing. Run `liquibase-shell` explicitly |
| DNS framed as the fix for unreachable `app.`/`api.` hosts | A 526 there is almost always a **missing ingress host rule / TLS entry**, not DNS |
| `deploy-service … --tag vX.Y.Z` shown as a clean one-liner | It pushes the image, then fails its own values bump with `Invalid version format`; bump `values.yaml` by hand |
| Verification via `/auth/sso/providers` | That path 404s — the real one is `/api/v1/auth/sso/providers` |

All of the above, with the reasoning and the working commands, is in
[`docs/authentik-oidc-setup.md`](authentik-oidc-setup.md).
