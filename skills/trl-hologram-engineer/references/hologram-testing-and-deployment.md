# Hologram Testing & Deployment

How to test Hologram pages/components and ship them. Both areas are lightly documented (pre-1.0); this captures the current state and pragmatic guidance.

## Testing

> There is **no first-party testing doc page yet** — a "Testing Toolkit" is on the roadmap as a *planned* item. The guidance below reflects the current ecosystem state.

### Where tests live

Tests live under `test/` as usual. The Hologram formatter config includes `test/**/*.{ex,exs,holo}`, so `.holo` templates referenced in tests are formatted too.

### The two layers

| Layer | Tool | Use for |
|-------|------|---------|
| **Browserless page/component tests** | **Mirage** (community project: "Browserless testing for Hologram pages and components") | Fast unit-style tests of rendering, state, and action logic without a real browser |
| **Feature / browser tests** | Phoenix feature testing / a browser driver | Anything involving **JS interop** (no-op during SSR, not unit-testable) and full-stack action→command→realtime flows |

### What must be a feature (browser) test

- **JavaScript interop** — interop functions are no-ops during SSR and are not unit-testable; only a real browser exercises them.
- **End-to-end interaction flows** where you want to assert the actual DOM after client actions.

### Practical strategy

1. **Pure server logic** (commands' business logic, changeset validation) — plain ExUnit tests, no Hologram needed.
2. **Component render + action state transitions** — Mirage (browserless).
3. **Interop + full interaction paths** — feature/browser tests.
4. Keep client-reachable code **pure and small** so most of it is testable without a browser; concentrate untestable interop behind narrow, clearly-marked functions.

> Verify current Mirage APIs and any emerging first-party helpers against their docs and the installed Hologram version — this space is moving.

## Deployment

> There is **no dedicated deployment doc page.** Deployment follows from the build model.

### The model

A Hologram app **is a Phoenix app**. Deploy it like any Phoenix / OTP release:

1. The **`:hologram` mix compiler** produces the client JS bundle at build time.
2. The Phoenix endpoint serves Hologram's runtime bundle from the **`"hologram"` static path** (configured during install).
3. Build the standard release (`mix release` / your normal Phoenix pipeline).

**Build-time requirement:** Node.js **20+** must be available where you build (the JS toolchain runs during compilation). Ensure your CI/build image includes Node, even if the runtime image does not.

### Server-side concerns tied to deployment

- **Session** is stored in a secure, integrity-protected cookie. Ensure your endpoint secret/signing config is set (as with any Phoenix session).
- **Cookies** default to `http_only: true`, `same_site: :lax`, `secure: true`. Keep `secure: true` in production (requires HTTPS).
- **SSE transport** for Realtime is a long-lived HTTP response — make sure proxies/load balancers do not buffer or prematurely close SSE streams (disable response buffering on the Realtime path; allow long-lived connections).

### Pre-deploy checklist

- [ ] `mix compile` is clean — no transpilation warnings (unsupported client code fails loudly)
- [ ] Node 20+ present in the build environment
- [ ] Endpoint serves the `"hologram"` static path
- [ ] `Hologram.Router` mounted before the Phoenix router
- [ ] Session signing secret configured; cookies `secure: true`
- [ ] Proxy/LB configured to allow SSE (no buffering, long-lived connections) if using Realtime
- [ ] Feature tests pass for any JS-interop paths
