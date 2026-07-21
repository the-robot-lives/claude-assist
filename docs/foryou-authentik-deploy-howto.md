# Foryou Authentik Deployment Howto

Use this when standing up `foryou.therobotlives.com` or another start-app-derived service with Authentik OIDC.

## DNS

Do not rely on the `*.therobotlives.com` wildcard CNAME for app hosts. Cloudflare can reject cross-account aliases with error `1014 CNAME Cross-User Banned`.

Add an explicit proxied `A` record in `terraform/cloudflare/zones/therobotlives.com/main.tf`:

```hcl
resource "cloudflare_dns_record" "foryou" {
  zone_id = local.zone_id
  name    = "foryou"
  type    = "A"
  content = local.ip
  proxied = true
  ttl     = 1
}
```

Apply only the zone after review:

```bash
cd terraform/cloudflare/zones/therobotlives.com
terragrunt plan
terragrunt apply
```

## Secrets

Keep the app and Authentik on the same OIDC client material. Add the app to the combined group in `.infisical-secrets.yaml`:

```yaml
groups:
  foryou-auth: [platform-authentik, foryou]
```

The `/platform/authentik` section needs `FORYOU_OIDC_CLIENT_ID` and `FORYOU_OIDC_CLIENT_SECRET`; the `/apps/foryou` section needs the same keys. Both should resolve from the same `dc` paths:

```yaml
dc: services apps.foryou_oidc_client_id
dc: services apps.foryou_oidc_client_secret
```

Populate without printing secret values. In non-interactive/headless shells, run the two sections separately; the grouped `foryou-auth` section may try to use `zellij` through the secret utility wrapper.

```bash
infisical-populate-secrets --prod --section platform-authentik --impacted
infisical-populate-secrets --prod --section foryou --impacted
```

Then let the Infisical operator sync Kubernetes secrets, or reconcile the relevant `InfisicalSecret` resources if needed.

## Authentik API

Use the API token from direnv config or an environment variable. Do not print it.

```bash
AUTHENTIK_HOST=https://auth.derobot.is
AUTHENTIK_TOKEN="$(dc get auto authentik_api_token --raw)"
FORYOU_OIDC_CLIENT_ID="$(dc get services apps.foryou_oidc_client_id --reveal --raw)"
FORYOU_OIDC_CLIENT_SECRET="$(dc get services apps.foryou_oidc_client_secret --reveal --raw)"
```

Create or update:

1. OAuth2/OpenID provider:
   - name: `foryou`
   - client type: confidential
   - client id: `FORYOU_OIDC_CLIENT_ID`
   - client secret: `FORYOU_OIDC_CLIENT_SECRET`
   - redirect URI: `https://foryou.therobotlives.com/auth/oidc/callback`
   - include local callback URIs when testing: `http://localhost:5585/auth/oidc/callback` and `http://127.0.0.1:5585/auth/oidc/callback`
   - issuer mode: per-provider
   - signing key: use Authentik's default signing key unless a service-specific key is required.
2. Application:
   - name: `For You`
   - slug: `foryou`
   - provider: the provider created above.
   - launch URL: `https://foryou.therobotlives.com/`

Verify discovery:

```bash
curl -fsS https://auth.derobot.is/application/o/foryou/.well-known/openid-configuration
```

## App Deployment

The Helm values must point the backend at Authentik:

```yaml
sso:
  requireInvite: false
  oidc:
    issuer: "https://auth.derobot.is/application/o/foryou"
```

The chart must route `/auth/sso-callback` to the frontend before the backend `/auth` prefix, because Authentik returns to the backend at `/auth/oidc/callback`, and the backend redirects the browser to the frontend callback page.

Build and ship both images with a semver tag, then deploy once:

```bash
deploy-service foryou.therobotlives.com/backend --prod --tag v0.1.0 --skip-deploy -y
deploy-service foryou.therobotlives.com/frontend --prod --tag v0.1.0 --skip-deploy -y
deploy-service foryou.therobotlives.com/backend foryou.therobotlives.com/frontend --prod --skip-build -y
```

Verify:

```bash
curl -fsS https://foryou.therobotlives.com/api/v1/auth/sso/providers
curl -I https://foryou.therobotlives.com/login
```
