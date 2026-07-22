# Tomorrow Prompt - The Robot Learns

Date: 2026-07-23

Continue work on `projects/therobotlearns.com` as the cloud application for The Robot Learns.

Current live state:

- `therobotlearns.com` is deployed and live through Helm release `therobotlearns` in namespace `apps`.
- The current deployed image is `ops.noizu.com/therobotlearns.com/web:f725dedb35c`.
- The page is a static nginx marketing/landing page, not yet the starter-app Elixir backend + Next.js frontend pattern.
- The broken display from 2026-07-22 was caused by Cloudflare serving stale `/styles.css` against newer HTML. This was fixed by cache-busting asset URLs and adding nginx cache headers.
- Authentik redirect currently exists at `/auth/oidc` and points to `https://auth.derobot.is/application/launch/therobotlearns/`.
- Direct signup/login in the landing modal is still not real account infrastructure. Do not treat the static form as production auth.

Next work prompt:

Implement The Robot Learns using the established starter-app pattern: Elixir/Phoenix backend, Next.js frontend, Postgres persistence, Helm deployment, Infisical-managed secrets, Authentik OIDC login, and invite-gated direct signup.

Priorities:

1. Replace the static-only deployment with a proper starter-app style backend/frontend deployment for TRL.
2. Keep the marketing landing page as the public first screen, but move it into the Next.js frontend.
3. Wire real auth:
   - Authentik OIDC login/sign-up should not require an invite token.
   - Direct email/password signup must require a valid invite token.
   - Direct signup without an invite should fail closed or create only a pending account if explicitly supported by the backend policy.
4. Add TRL app secrets in Infisical configuration without committing real secret values:
   - database credentials or database URL
   - Phoenix `SECRET_KEY_BASE`
   - Guardian/JWT secret
   - OIDC client id and secret
   - invite token seed/config strategy
5. Add or provision the TRL database role/database using the repo's existing app database pattern.
6. Update `.infra-config.yaml` so docker build metadata has separate `backend` and `frontend` images if the starter-app split is used.
7. Update Helm templates/values to route:
   - `/api`, `/auth`, `/sso`, and health endpoints to the backend
   - `/` to the frontend
8. Build, push, Helm upgrade, and verify:
   - public landing renders correctly
   - `/auth/oidc` reaches Authentik
   - direct signup rejects missing/invalid invite tokens
   - direct signup accepts a valid configured beta invite token
   - email login works for a created direct account
   - no pricing copy is introduced

Useful context from 2026-07-22:

- Relevant commits:
  - `8c93d3945a3` - `Improve therobotlearns beta landing UX`
  - `73541de3862` - `Pin therobotlearns web image`
  - `f725dedb35c` - `Fix therobotlearns asset cache mismatch`
  - `81f14b6a368` - `Pin therobotlearns cache fix image`
- The current static landing assets are in:
  - `web/index.html`
  - `web/styles.css`
  - `web/app.js`
  - `nginx.conf`
- Starter-app auth reference points:
  - `components/start-app/backend/lib/starter_web/controllers/auth_controller.ex`
  - `components/start-app/backend/config/runtime.exs`
  - `components/start-app/frontend/src/app/login/page.tsx`
  - `components/start-app/frontend/src/app/signup/page.tsx`
  - `components/start-app/helm/start-app/`

Guardrails:

- Do not commit plaintext invite tokens or OIDC secrets.
- Do not revert unrelated dirty files in the monorepo.
- Do not add pricing copy; the public page should sell features and free beta access only.
- Keep the CLI/MCP positioning clear: local tooling is for pushing, reading, learning, and planning content; the cloud app owns accounts, sync, teams, dashboards, and shared workflows.
