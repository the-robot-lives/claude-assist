# Carpet Grand Prix — Platform

Other staged games in this workshop carry an `AGENT-SYSTEM.md`, `ECONOMY.md`,
`GAME-API.md`, and `MARKETPLACE.md` alongside their platform architecture.
Carpet Grand Prix does not, and that absence is a decision, not an omission.

Carpet Grand Prix is a **single-player, premium, offline iOS app.** $4.99,
one purchase, no ads, no IAP, no currency. It has:

- **No agents.** There is nothing in this game an AI or a third party could
  operate — no NPCs, no shopkeepers, no persistent world population. `AGENT-SYSTEM.md`
  does not apply.
- **No economy.** There is no currency, no conversion mechanism, no wallet,
  no billing meter. Progression is medals and best times, stored on-device.
  `ECONOMY.md` does not apply.
- **No server API.** `Support/Persistence.swift` is the entire backend, and
  it is local storage — `UserDefaults` and on-device JSON files. There is no
  network call anywhere in the gameplay path, no account, and therefore
  nothing for a `GAME-API.md` to document.
- **No marketplace.** Nothing is bought, sold, traded, or listed inside the
  game. The one paid expansion (`The Garage Sale`, M21) is a normal App Store
  in-app purchase, not an in-game economy transaction. `MARKETPLACE.md` does
  not apply.

The technical architecture that *does* exist — the SwiftUI shell, the pure
simulation core, the CoreMotion input layer, and the hand-written Metal
renderer — is documented in full in `platform/PLATFORM-ARCHITECTURE.md`.
That document is the only platform document this game needs.
