# Timely iOS

The iOS **companion** for Timely. It reviews evidence the macOS agent captured;
it captures nothing itself.

It has no screenshot capture, no background capture, and no always-on timer, and
it declares no entitlements that would allow any of them. What it does:

- day review with visible confidence on every interval
- timeline browsing and correction — split, merge, reassign, retitle, re-bill
- manual entry
- idle-gap resolution
- reports, server-backed with a labelled local fallback
- privacy and settings, including the device half of the screenshot upload gate

## Architecture

All models, canonicalization, local storage, sync and auth come from
[`../shared/TimelyKit`](../shared/TimelyKit), wired in as a local path
dependency. **Nothing in this target reimplements them.** The app layer is:

| Layer | Path | What lives there |
|---|---|---|
| Domain | `Sources/TimelyiOS/Domain` | Pure logic: rollups, idle-gap detection, confidence labelling, review-item derivation, correction plans, formatting |
| App | `Sources/TimelyiOS/App` | Composition root, configuration, identity, the repository over `TimelyLocalStore` |
| Auth | `Sources/TimelyiOS/Auth` | OIDC via `ASWebAuthenticationSession`, behind a testable protocol |
| View models | `Sources/TimelyiOS/ViewModels` | `@MainActor @Observable` state; no networking in views |
| Views | `Sources/TimelyiOS/Views` | SwiftUI |
| Design | `Sources/TimelyiOS/Design` | The macOS style guide translated to iOS |

Corrections are expressed as a `SpanCorrectionPlan` — a value describing the
creates, updates and deletes that carry them out — so split and merge match
`SYNC-PROTOCOL.md` §7.3 exactly and are unit-testable without a store.

## Offline behaviour

**The app is fully usable read/write with no session and no network.** On first
launch it mints a provisional workspace id and works immediately; signing in
later re-keys those records onto the real workspace through
`TimelyLocalStore.rebindWorkspace`, which re-derives every UUIDv5 taxonomy id.

Sync state is reported and never enforced. There is no "you must be online to
edit" path anywhere in this target, and `OfflineWorkflowTests` exists to keep it
that way: every test in it runs with no session and a transport that throws on
contact.

## Build

The package is declared **iOS-only**, so `swift build` — which targets macOS on a
Mac — will not build it. Use `xcodebuild`.

```bash
# Compile the app sources for the simulator
xcodebuild -scheme TimelyiOS -destination 'generic/platform=iOS Simulator' build

# Run the tests on a simulator
xcodebuild -scheme TimelyiOS -destination 'platform=iOS Simulator,name=iPhone 17' test
```

### Running it as an app

`project.yml` drives [XcodeGen](https://github.com/yonaskolb/XcodeGen). The
generated `.xcodeproj` is gitignored; regenerate it rather than committing it.

```bash
xcodegen generate
xcodebuild -project TimelyiOS.xcodeproj -scheme TimelyiOS \
  -destination 'generic/platform=iOS Simulator' build
```

The app target compiles `Sources/TimelyiOS` directly alongside `App/`, so the
SwiftPM library and the shipped binary are always the same code.

> **Regenerate after adding a file.** XcodeGen enumerates sources at generation
> time and freezes the list into the `.xcodeproj`, and a `.xcodeproj` present in
> this directory *shadows the package* for a bare `xcodebuild -scheme TimelyiOS`.
> A file added afterwards is silently excluded while the build still reports
> success — a new test suite can appear to pass when it never compiled. Either
> re-run `xcodegen generate`, or delete the project and build the package, which
> discovers sources automatically. Check the suite count moved.

**Signing is off** (`CODE_SIGNING_ALLOWED: NO`) because no identity is
provisioned in this repo. For a device build or TestFlight, set a development
team in `project.yml` and add an app icon asset catalog.

## Configuration

Read from `App/Info.plist` at launch, so one binary serves several environments:

| Key | Meaning |
|---|---|
| `TimelyAPIBaseURL` | Backend origin |
| `TimelyOIDCEnabled` | Whether to offer single sign-on |
| `TimelyOIDCCallbackScheme` | Custom scheme the sign-in session completes on; must match `CFBundleURLTypes` |

## Single sign-on

Two sign-in paths, producing the same `AuthTokens` and the same refresh
behaviour, so nothing downstream branches on how the user signed in:

- email/password against `POST /api/v1/auth/login`
- OIDC against Authentik, brokered by the backend

### The native flow

1. `GET /auth/oidc?redirect_uri=…&code_challenge=…&code_challenge_method=S256`,
   opened in `ASWebAuthenticationSession`.
2. The backend performs the OIDC dance — it is the OAuth client and holds the
   secret; **this app never talks to the IdP.**
3. The browser lands back on the app's custom scheme with `?code=…`.
4. `POST /api/v1/auth/sso/exchange` with `{"code": …, "code_verifier": …}`.

**The redirect URI is exactly:**

```
com.noizu.timely://auth/callback
```

The backend's `SSO_REDIRECT_ALLOWLIST` matches this **exactly, not by prefix** —
a prefix check would accept `com.noizu.timely://auth/callback@evil.example`,
which is a different destination wearing the right beginning. `OIDCAuthenticatorTests`
pins the literal so drift fails a test rather than the flow.

### Custom scheme now, Universal Link later

A Universal Link is the better mechanism and is the intended destination: it is
**ownership-verified**, so a malicious app cannot receive the redirect at all,
and PKCE becomes defence in depth rather than the only control. A custom scheme
is claimed by pattern — any app may register `com.noizu.timely://`.

It is not adoptable yet. Three independent blockers, each sufficient on its own:

1. **No Team ID exists.** This repo has no provisioning identity
   (`CODE_SIGNING_ALLOWED: NO`, no `DEVELOPMENT_TEAM`). The server needs
   `IOS_APP_IDS=TEAMID.com.noizu.timely`, and the app needs an Associated
   Domains entitlement (`applinks:timely.noizu.com`), which requires a
   provisioning profile carrying that capability.
2. **The API needs iOS 17.4; this app targets 17.0.** An https callback requires
   `ASWebAuthenticationSession.init(url:callback:)` with
   `.https(host:path:)`, marked `API_AVAILABLE(ios(17.4))` in
   `ASWebAuthenticationSession.h`. The older `init(url:callbackURLScheme:)`
   accepts a custom scheme only. Moving means dropping iOS 17.0–17.3, which is a
   product decision, not a build setting.
3. **It cannot be verified from here, and it fails hard.** iOS caches the
   association file aggressively and offers no disambiguation fallback — a bad
   or missing file is a dead flow, not a degraded one. Shipping an unverifiable
   hard-failure path is the wrong trade against a custom scheme whose registration
   is verifiable today (`simctl openurl` routes it to the app).

The allow-list holds **both** entries simultaneously, so the migration is a
client-only change once these clear:

```
SSO_REDIRECT_ALLOWLIST=https://timely.noizu.com/app/auth/callback,com.noizu.timely://auth/callback
```

- [x] ~~ops adds the https literal to `SSO_REDIRECT_ALLOWLIST`~~ — **already
      live**, because Android chose the same string for its App Link. No server
      change is needed to switch.
- [ ] Apple Developer Team ID; set `DEVELOPMENT_TEAM` in `project.yml`
- [ ] ops sets `IOS_APP_IDS=TEAMID.com.noizu.timely`; confirm
      `/.well-known/apple-app-site-association` returns 200 (it 404s while
      unconfigured, deliberately — a well-formed file with a non-matching ID is
      a definitive rejection, so do not guess the Team ID)
- [ ] add the `com.apple.developer.associated-domains` entitlement,
      `applinks:timely.noizu.com`
- [ ] raise the deployment target to 17.4
- [ ] switch `WebAuthenticationPresenter` to `init(url:callback:)` with
      `.https(host: "timely.noizu.com", path: "/app/auth/callback")`
- [ ] retire the custom scheme once no old build is in the field

### Why PKCE, given the server holds the secret

This is **not** PKCE against the identity provider. It protects *our* code
exchange, because a custom URL scheme is claimed **by pattern, not owned**: any
app on the device may register `com.noizu.timely://` and receive the redirect.
Single-use codes with a 60-second TTL do not help — whoever redeems first gets a
full token pair. The verifier is the one thing an interceptor does not have.

S256 only (`plain` is refused). A fresh verifier per flow, never logged, never
persisted. It is optional server-side; this client always sends it.

### Errors

The seven documented codes arrive as `?error=<code>` on the **same** custom
scheme as success — deliberately, because an error rendered as a web page would
leave the session open with nothing to return to. `SSOErrorCode` maps each to a
sentence a person can act on, and marks which are retryable and which should
point at the password form instead:

| Code | Retryable | Suggests password |
|---|---|---|
| `redirect_not_allowed` | no | no |
| `invalid_code_challenge` | yes | no |
| `state_mismatch` | yes | no |
| `not_provisioned` | no | yes |
| `sso_unavailable` | no | yes |
| `sso_failed` | yes | no |
| `oidc_failed` | yes | no |

An unrecognized code degrades to a readable message rather than reading as a
missing code, since new codes can ship without a client release.

## What was replaced

The previous scaffold's `Models.swift` (duplicate `TimelyInterval`,
`TimelySummary`, `IdlePrompt`, `ClientReport`, `TimelyPolicy`, `TimelyStore`) and
its inline sample data are gone. Duplicating contract models across surfaces is
the specific failure TimelyKit exists to prevent. The tab shell from the old
`RootView.swift` survives in spirit: Review is promoted out of Today because
unanswered duplicate and overlap flags are what block an invoice, and Privacy
folds into Settings next to the policy that constrains it.
