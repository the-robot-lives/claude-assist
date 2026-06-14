# Authentik Auth Setup for Portfolio Sites

Step-by-step guide for adding Authentik-based login to a static-export Next.js portfolio site. Uses OAuth 2.0 Authorization Code + PKCE (no backend needed).

## Prerequisites

- Authentik instance running at `https://auth.derobot.is`
- A Next.js site with `output: "export"` in `next.config.ts`
- Access to `.envrc.dc` and `.infisical-secrets.yaml`

---

## 1. Provision the Authentik Application

Create the OAuth2 provider and application via the Authentik API. Requires an API
token (create at Admin > Directory > Tokens, intent: API).

You'll need these UUIDs from your Authentik instance (find via the admin UI or API):
- `AUTH_FLOW` — default authorization flow UUID
- `INVAL_FLOW` — default invalidation flow UUID
- `SIGNING_KEY` — OIDC signing key UUID
- `PROP_MAPS` — array of property mapping UUIDs (openid, email, profile)

### Create provider + application

```bash
AUTHENTIK_TOKEN="<token>"
AUTH_FLOW="<uuid>"
INVAL_FLOW="<uuid>"
SIGNING_KEY="<uuid>"
PROP_MAPS='["<uuid>","<uuid>","<uuid>"]'

SLUG="aifighter"
DOMAIN="aifighter.com"
NAME="AI Fighter"

# Create OAuth2 provider (public client, PKCE)
PROVIDER_RESULT=$(curl -s -X POST \
  -H "Authorization: Bearer $AUTHENTIK_TOKEN" \
  -H "Content-Type: application/json" \
  "https://auth.derobot.is/api/v3/providers/oauth2/" \
  -d "{
    \"name\": \"$SLUG\",
    \"authorization_flow\": \"$AUTH_FLOW\",
    \"invalidation_flow\": \"$INVAL_FLOW\",
    \"property_mappings\": $PROP_MAPS,
    \"client_type\": \"public\",
    \"redirect_uris\": [
      {\"matching_mode\": \"strict\", \"url\": \"https://$DOMAIN/auth/callback\"},
      {\"matching_mode\": \"strict\", \"url\": \"http://localhost:3000/auth/callback\"}
    ],
    \"access_code_validity\": \"minutes=1\",
    \"access_token_validity\": \"minutes=5\",
    \"refresh_token_validity\": \"days=30\",
    \"include_claims_in_id_token\": true,
    \"signing_key\": \"$SIGNING_KEY\",
    \"sub_mode\": \"hashed_user_id\",
    \"issuer_mode\": \"per_provider\"
  }")

PK=$(echo "$PROVIDER_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['pk'])")
CID=$(echo "$PROVIDER_RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['client_id'])")
echo "Provider PK=$PK  Client ID=$CID"

# Create application linked to provider
curl -s -X POST \
  -H "Authorization: Bearer $AUTHENTIK_TOKEN" \
  -H "Content-Type: application/json" \
  "https://auth.derobot.is/api/v3/core/applications/" \
  -d "{
    \"name\": \"$NAME\",
    \"slug\": \"$SLUG\",
    \"provider\": $PK,
    \"launch_url\": \"https://$DOMAIN\",
    \"open_in_new_tab\": true,
    \"meta_launch_url\": \"https://$DOMAIN\",
    \"policy_engine_mode\": \"any\"
  }"
```

The API returns an Authentik-generated `client_id` — copy it into `src/lib/auth.ts`.

### Batch provisioning

To create multiple sites at once, pipe a list through a loop:

```bash
SITES="slug1|domain1.com|Display Name 1
slug2|domain2.com|Display Name 2"

echo "$SITES" | while IFS='|' read -r slug domain name; do
  # ... same curl calls as above with $slug, $domain, $name
done
```

---

## 2. Add the Auth Library

Create `src/lib/auth.ts`:

```typescript
const AUTHENTIK_BASE = "https://auth.derobot.is/application/o";
const CLIENT_ID = "<paste-client-id-here>";
const REDIRECT_URI =
  typeof window !== "undefined"
    ? `${window.location.origin}/auth/callback`
    : "https://<domain>/auth/callback";
const SCOPES = "openid email profile";
```

The file implements:
- `startLogin()` — generates PKCE challenge, redirects to Authentik
- `handleCallback(code)` — exchanges auth code for tokens via POST to `/token/`
- `getUser()` — decodes the JWT id_token to extract email/name
- `isLoggedIn()` — checks for access_token in localStorage
- `logout()` — clears tokens, redirects to `/`

See `projects/therobotmakes.com/web/src/lib/auth.ts` for the reference implementation.

---

## 3. Add the Callback Page

Create `src/app/auth/callback/page.tsx`:

- Wraps handler in `<Suspense>` (required for `useSearchParams()` in static export)
- Reads `?code=` from the URL
- Calls `handleCallback(code)` to exchange for tokens
- On success: `router.replace("/dashboard")`
- On failure: shows error with "Back to home" link

---

## 4. Add the Dashboard Stub

Create `src/app/dashboard/page.tsx`:

- `"use client"` component
- On mount, checks `isLoggedIn()`; if false, calls `startLogin()` (auto-redirect)
- Decodes user info from id_token via `getUser()`
- Shows nav with user email + "Sign Out" button
- Empty-state body with placeholder for future features

---

## 5. Add Sign In to the Landing Page

Update `src/app/page.tsx`:

1. Add `"use client"` directive at top
2. Import `startLogin` from `@/lib/auth`
3. Add a Sign In button to the nav that calls `startLogin()`

```tsx
<button onClick={() => startLogin()} className="nav-signin">
  Sign In
</button>
```

---

## 6. Update CSS

Add styles for `.nav-actions` (flex container for Sign In + existing CTA) and `.nav-signin` (ghost-style button matching the site's design tokens).

---

## 7. Verify the nginx SPA Fallback

The `nginx.conf` must have a `try_files` directive that falls back to `index.html` so that `/auth/callback` and `/dashboard` routes work after static export:

```nginx
location / {
    try_files $uri $uri.html $uri/index.html /index.html;
}
```

This is already present in the standard static-site nginx.conf template.

---

## 8. Build and Deploy

```bash
# Local test
cd web && npm run dev
# Visit http://localhost:3000, click Sign In

# Production build + deploy
docker-build <image-key> --push
helm-upgrade --include <release-name>
```

---

## Auth Flow Diagram

```
User clicks "Sign In"
  |
  v
startLogin() generates PKCE verifier/challenge
  |
  v
Redirect to auth.derobot.is/application/o/authorize/
  (client_id, redirect_uri, code_challenge, scope)
  |
  v
User authenticates with Authentik (email/password, SSO, etc.)
  |
  v
Authentik redirects to https://<domain>/auth/callback?code=xyz
  |
  v
handleCallback() POSTs to auth.derobot.is/application/o/token/
  (code, client_id, code_verifier)
  |
  v
Tokens stored in localStorage (access_token, id_token, refresh_token)
  |
  v
Redirect to /dashboard
```

---

## Token Storage

| Key | Storage | Purpose |
|-----|---------|---------|
| `pkce_verifier` | sessionStorage | Temporary, cleared after token exchange |
| `access_token` | localStorage | Bearer token for future API calls |
| `id_token` | localStorage | JWT with user claims (email, name) |
| `refresh_token` | localStorage | Token refresh (if provided by Authentik) |

---

## Checklist for New Sites

- [ ] Create Authentik provider + application via API (see step 1)
- [ ] Copy the Authentik-generated client ID into `src/lib/auth.ts`
- [ ] Add `src/lib/auth.ts` (copy from reference)
- [ ] Add `src/app/auth/callback/page.tsx`
- [ ] Add `src/app/dashboard/page.tsx`
- [ ] Add "Sign In" button to landing page nav
- [ ] Add nav CSS for sign-in button
- [ ] Verify `nginx.conf` has SPA fallback
- [ ] Test locally with `npm run dev`
- [ ] Build, push, deploy
- [ ] Verify production login flow end-to-end

---

## Sites Using This Pattern

| Site | Client ID | Status |
|------|-----------|--------|
| therobotmakes.com | `MowL88RkG3clbZqUG7xe7UyvQBwammpgVbKhy4kV` | Live |
| aifighter.com | `Lyc70pGc8GsjkaYZK4HfA98YhH21L5KvoH5qXuzw` | Live (v1.0.1) |
| therobotknows.com | `Y6i1poQYWuMVaHRMwaF4d7BXPcEkogBPac4Bajaj` | Auth + dashboard wired |
| tobornalp.com | `A01hQoShQ64g8Jx31PDgITCOFLtS4CWBXLQcJ3Ms` | Auth + dashboard wired |
| iotgo.io | `UZZsrEpUs07UMPiqAU8jZcLEzwPNg590alUwKjMQ` | Auth + dashboard wired |
| jailbreakingsite.com | `GzIIttiAnGpBGoL76tYFHq87jmPO3XbSPiAX8TrE` | Auth ready |
| derobot.is | `AmqQip6vOltvOr08jnhZgklAboVNninZvVfY06Nf` | Auth + dashboard wired |
| gotta.cc | `6w7xDcDlQrKYnaYj2BYc7ra1M1O3ZeTePftAkPIX` | Auth + dashboard wired |
| therobotlives.com | `hlllSFvMEx1kcSfcLiaF6OnOp9fEClwMrTANbkCj` | Auth ready |
