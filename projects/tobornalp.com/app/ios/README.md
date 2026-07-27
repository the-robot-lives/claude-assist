# TheRobotPlans iOS

Universal SwiftUI app shell for TheRobotPlans on iPhone and iPad.

The checked-in package follows the lightweight native-app pattern used elsewhere
in this monorepo: source and tests are committed, generated Xcode projects are
ignored. The app is designed as a mobile companion for the existing Phoenix and
Next.js product at `therobotplans.com` / `tobornalp.com`.

## Scope

- iPhone: fast capture, today review, agent/team status, and settings in a tab shell.
- iPad: split-view operations cockpit with lanes, item detail, capture queue, and agent readiness.
- Offline-first core models for capture and review flows.
- Testable Foundation-only domain target.

## Layout

| Path | Purpose |
|---|---|
| `Sources/TheRobotPlansCore` | Shared domain models, sample bootstrap data, and read-model helpers. |
| `Sources/TheRobotPlansiOS` | SwiftUI app, adaptive iPhone/iPad navigation, and mobile screens. |
| `Tests/TheRobotPlansCoreTests` | Host-runnable unit tests for mobile read models and capture drafts. |

## Build And Test

Run the host-safe domain tests:

```bash
swift test
```

Build the universal SwiftUI app for a simulator from Xcode or with:

```bash
xcodebuild -scheme TheRobotPlansiOS -destination 'generic/platform=iOS Simulator' build
```

The Swift package is the source of truth. If a generated Xcode project is added
later, regenerate it after adding files so new sources are included.

## Backend Contract

The native app should use the same canonical API origin as the web app:

```text
https://therobotplans.com
```

The initial package uses local bootstrap data until the mobile API contract is
wired. The expected first endpoints are:

- `POST /api/v1/inbox/captures`
- `GET /api/v1/mobile/today`
- `GET /api/v1/mobile/lanes`
- `GET /api/v1/mobile/agents`
- `POST /api/v1/mobile/sync`

Deep links should preserve the web URL shape where possible so links can move
between the browser and native apps without losing workspace context.
