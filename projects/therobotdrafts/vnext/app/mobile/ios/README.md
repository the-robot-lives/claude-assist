# The Robot Draft - iPhone/iPad

Native SwiftUI companion app for the vNext backend in `../../backend`.

```
make generate
make build
make test
```

The app uses XcodeGen, so `RobotDrafts.xcodeproj` is generated locally and is
not checked in.

## Backend

The default backend URL is `http://localhost:4000`, which works for an iOS
Simulator when the Phoenix backend is running locally. For a physical device,
set the backend URL in the app settings to an HTTPS deployment such as
`https://draft.therobotplans.com`, or to a LAN-reachable dev URL if ATS allows
it.

Project-backed documents require a signed-in backend user and a project UUID.
Fixture documents use the public `/api/v1/holograph/docs` surface so the app can
verify connectivity before account setup is complete.

## Layout

```
RobotDrafts/
├── App/          SwiftUI entry point and plist
├── Design/       Shared colors and small visual helpers
├── Models/       Codable API models
├── Networking/   REST client and token storage
├── Stores/       MainActor view models
└── Views/        Adaptive iPhone/iPad screens
Tests/            Model and API-client tests
```
