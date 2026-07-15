# Start-App Scaffolding

Use `start-app-scaffold` to hydrate a portfolio app from `components/start-app`
and generate local provisioning artifacts.

```bash
start-app-scaffold \
  --project-dir example.com \
  --slug example \
  --module Example \
  --app-name "Example" \
  --tagline "Operational dashboard" \
  --site example.com \
  --theme starter
```

By default the target is `projects/<project-dir>/app`. The utility writes:

- `.env` values for frontend, backend, nginx, SSO, app domain, and cookie domain.
- `.start-app-provision/helm-values.generated.yaml`.
- `.start-app-provision/provision-postgres.sql`.
- `.start-app-provision/provision-valkey.acl`.
- `.start-app-provision/summary.txt`.

Use `--execute --postgres-url <admin-url> --valkey-url <admin-url>` to apply the
generated database and Valkey ACL provisioning.

## SSO Domain Policy

Generated Helm values include SSO availability and approval policy placeholders:

```yaml
sso:
  domains: "example.com=oidc"
  autoApproveDomains: ""
```

`domains` controls whether SSO is offered for an email domain and which providers
are valid. `autoApproveDomains` controls which SSO-enabled domains bypass manual
approval. Domains not listed in `autoApproveDomains` can still use SSO, but new
users remain pending unless they redeem a valid invite.

## Generated Test Coverage

The scaffold keeps the Cypress+Cucumber suite in `frontend/cypress/` and rewrites
the default app identity in `frontend/cypress.config.ts`:

- `CYPRESS_APP_NAME`
- `CYPRESS_TAGLINE`
- `CYPRESS_SITE_DOMAIN`
- `CYPRESS_APP_DOMAIN`
- `CYPRESS_SSO_DOMAIN`
- `CYPRESS_PASSWORD_DOMAIN`

The suite covers generated-app smoke paths:

- SSO-domain login shows SSO instead of password first.
- Password signup submits profile details and invite token.
- SSO callback routes incomplete users to registration completion.
- Cookie choices persist optional preferences while keeping required cookies on.

Run from the generated app frontend:

```bash
npm run test
npm run test:e2e
```

For local E2E runs, start the app first and override the base URL if needed:

```bash
CYPRESS_BASE_URL=http://localhost:3000 npm run test:e2e
```
