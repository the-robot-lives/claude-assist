# Billing Noizu App Prototype

This directory contains the first implementation pass for the Billing Noizu product surface.

| Path | Purpose |
|------|---------|
| `web/` | Dependency-free web app prototype for the canonical billing workspace |
| `shared/contracts/` | API/deep-link contract used by web, iOS, Android, and macOS |
| `shared/design/` | Cross-platform design tokens |
| `ios/` | SwiftUI source for the iOS mobile review companion |
| `macos/` | SwiftUI source for the macOS receivables cockpit |
| `android/` | Kotlin/Jetpack Compose source for the Android mobile review companion |

## Run The Web App

Open `web/index.html` in a browser. It is static and does not need a dev server.

The production-shaped Next.js app is also scaffolded in `web/src/`. After dependencies
are installed:

```bash
cd projects/billing.noizu.com/app/web
npm install
npm run dev
```

## Implementation Scope

The web prototype implements the MVP product shape: receivables summary, invoice queue, invoice detail/send scaffolds, payment-method readiness, record-payment workflow, customer risk, platform readiness, and audit states. The Next.js tree turns that shape into routeable pages. Native app folders contain package/project manifests plus source-level starting points that consume the same concepts and contracts.

## Next Engineering Steps

1. Scaffold the production web app with the repo's `start-app` pattern when backend/API work starts.
2. Convert `shared/contracts/billing-api.yaml` into generated clients.
3. Implement the Phoenix invoice, send, payment-method, and payment-record endpoints behind the route scaffolds.
4. Replace Swift Package manifests with full Xcode projects when signing, previews, and TestFlight are needed.
5. Wire Android Gradle builds into CI once Android SDK tooling is available.
6. Replace empty readiness data with Phoenix API responses.
