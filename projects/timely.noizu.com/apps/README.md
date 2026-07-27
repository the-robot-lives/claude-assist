# Timely App Surfaces

This directory contains Timely's product surfaces: a Phoenix backend, a shared cross-platform contract library, and the macOS/iOS/Android/web clients.

| Surface | Path | Purpose | Current State |
|---------|------|---------|---------------|
| Backend | `backend/` | Phoenix + Hologram server: domain model, auth, and a versioned `/api/v1` JSON + offline-sync API | Implemented and tested (357/358, one known inherited SSO test failure - see `tomorrow.md`). Schema is Liquibase-owned (`backend/db/changelog/`), not Ecto-migrated. Deploy config is written but **not applied** - no image build/push, no `terraform apply`, no `helm upgrade`, no DNS yet. |
| Shared TimelyKit | `shared/TimelyKit/` | Swift package implementing the cross-platform sync contract - `canon()`, deterministic taxonomy ids, sync client, offline/expired-token handling, screenshot privacy gating - against [`shared/contracts/`](shared/contracts/) | Complete. 143/143 tests passing. Declared as a dependency of, and consumed by, both the macOS and iOS app targets. |
| macOS app | `macos/` | Desktop capture agent, menu/status, permissions, local capture state | Retrofitted onto TimelyKit for sync this session (new `TimelyStore+Sync.swift`, `TimelyKit+MacUI.swift`, `DeviceIdentity.swift`). `swift build` clean. No dedicated macOS test target - relies on TimelyKit's suite for sync/canon correctness; the macOS-specific UI has not been automated-tested. |
| iOS app | `ios/` | Mobile companion for day review, idle prompts, privacy, and reports | Rebuilt on TimelyKit. Sign-in, day review, timeline correction (split/merge/reassign), manual entry, idle resolution, review queue, reports and settings. Offline read/write with no session. 101 tests green; app builds and launches on the iOS 26.4 simulator via XcodeGen (`project.yml`), and via `xcodebuild` directly. Not done: no signed device build (no provisioning identity), no app icon asset catalog, no XCUITest. SSO blocked on a backend native-redirect gap - see `ios/README.md`. |
| Android app | `android/` | Mobile companion for review, idle prompts, and reporting checks | Independent `canon()` and sync-engine implementation - see `core/identity/Canon.kt` and `data/sync/`. 65+ tests passing across its test suite, 0 failures. |
| Web app | `web-app/` | Authenticated dashboard, timeline review, billing/reporting workspace | Dependency-free prototype |
| Web portal | `web-portal/` | Public product portal for positioning, trust, and alpha signup | Dependency-free prototype |

`shared/contracts/` (the OpenAPI wire contract and the executable `canon()`/taxonomy-id conformance fixture) and `docs/SYNC-PROTOCOL.md` are the normative cross-platform source of truth every client and the backend must agree with; see the repo root [README.md](../README.md) for the current state summary.

The dependency-free web surfaces can be opened directly in a browser, though a local static server is cleaner.

```bash
cd projects/timely.noizu.com
python3 -m http.server 4173
```

Then open:

- `http://127.0.0.1:4173/apps/web-app/`
- `http://127.0.0.1:4173/apps/web-portal/`
