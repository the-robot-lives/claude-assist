# Timely Android

Kotlin + Jetpack Compose **companion** app for Timely.

## What this app is, and is not

Android is a companion, not a capture agent (see `apps/README.md`). It reviews
and corrects time that the macOS agent recorded. It has:

- no screen capture, and no permission that would allow it
- no background capture service and no always-on timer
- no code path that uploads screenshot bytes

That last point is enforced structurally rather than by a setting -- see
`data/privacy/ScreenshotGate.kt` and the tests in `ScreenshotGateTest`.

## Build

```bash
./gradlew assembleDebug          # debug APK
./gradlew testDebugUnitTest      # unit tests, including the canon() gate
./gradlew assembleDebug testDebugUnitTest
```

Requires JDK 17 and an Android SDK with platform 35 / build-tools 35.0.0.
`local.properties` points at the SDK.

Debug builds talk to `http://10.0.2.2:4000/` (the emulator's route to a host
`localhost:4000`); release builds talk to `https://timely.noizu.com/`. Both are
`buildConfigField`s in `app/build.gradle.kts`.

## Conformance gate

`CanonConformanceTest` reads `apps/shared/contracts/canon-fixtures.json`
**directly** -- it is on the test resource path via a `srcDir`, not copied into
this module, because a copied fixture rots silently the moment the contract is
amended. It executes **every** `canon_case` and `composite_case` the fixture
contains -- whatever the count happens to be, since the corpus is expected to
grow -- and also asserts the implementation's code-point tables against the ones
the fixture declares.

That table assertion is not redundant with the behavioural cases. It is the only
thing that catches a code point the corpus does not happen to exercise: deleting
U+201F from the quote table fails the table assertion and *nothing else*.

A failure here is never "fix the test". It is a real divergence in `canon()` or
a contract change that has not been read yet. See SYNC-PROTOCOL.md section 14.

## Architecture

Room is the UI's only source of truth. Screens observe tables; the sync engine
is the only writer of server-derived state. Nothing on a write path consults
auth state, so the app is fully readable and writable offline with an expired
token, and edits queue until a session is available.

| Package | Role |
|---|---|
| `core/identity` | `canon()`, UUIDv5/v7, deterministic taxonomy ids |
| `data/local` | Room entities, DAOs, wire-to-local mappers |
| `data/remote` | Retrofit interfaces and wire DTOs |
| `data/sync` | Cursor pull, ordered push queue, conflict handling |
| `data/repo` | User-facing writes; local row + queued mutation, atomically |
| `data/privacy` | The screenshot gate |
| `work` | WorkManager periodic sync and manual refresh |
| `ui` | Compose screens, view models, theme |

## Known gaps

- No instrumented (`androidTest`) coverage yet; all tests are JVM/Robolectric.
- Reports are computed from the local mirror rather than `/reports/summary`, so
  they stay available offline but are not the server's invoicing numbers. The
  screen says so.
- The OIDC leg builds its endpoints from the issuer by convention rather than
  fetching the discovery document.
