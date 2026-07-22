# Changelog — utilities/osx/queue-populator

## [Unreleased]
- Regenerated `docs/PROJ-ARCH.md` and `docs/PROJ-LAYOUT.md` (+ summaries) to reflect current source layout.

## [m4-audio-reliability-fixes] — 2026-07-05 — tag: `utilities-osx-queue-populator/m4-audio-reliability-fixes`
Milestone summary: fixed two data-loss bugs in memo capture — audio exports were silently failing outright, and long recordings lost transcript content across recognizer restarts.

### Fixed
- `MemoAudioRecorder`: `afconvert` cannot encode MP3 on macOS, so every memo audio export failed silently. Now encodes real MP3 via `lame` (CAF→WAV→MP3), falls back to AAC `.m4a` via `afconvert`, and salvages the raw `.caf` as a last resort; releases the `AVAudioFile` before encoders read the capture and cleans up temp/partial files on every path.
- `SpeechEngine`: keeps the audio engine and mic tap alive for the whole session and rotates only the recognition request/task (generation-guarded, gap-free swap), flushing un-finalized partials into the transcript on rotation. Restarts on benign recognition errors instead of stopping capture mid-memo, giving up only after repeated immediate failures. Fixes transcript loss and audio gaps on long recordings.

## [m3-config-secrets-and-debug-tooling] — 2026-06-16 — tag: `utilities-osx-queue-populator/m3-config-secrets-and-debug-tooling`
Milestone summary: hardened configuration handling with env-var resolution and a dedicated secret store, added structured debug logging, and reworked the config dialog and transcript window UX; closed with a debugging pass.

### Added
- `EnvResolver` and `SecretStore` for resolving/storing config values (incl. secrets) outside plain config files
- `DebugLog` structured debug logging, threaded through `Coordinator` and the transcript window
- `BuildInfo` build metadata
- `install.sh` / `uninstall.sh` installer scripts

### Changed
- `ConfigDialog` substantially reworked (validation, layout, then simplified/consolidated in the follow-up debugging pass)
- `LlmConfig` extended to source values via `EnvResolver`
- `TranscriptWindow` gained additional debug-log-driven behavior
- `StatusBarController` updated for new config/debug wiring

## [m2-virtual-mic-and-memo-review] — 2026-06-14 — tag: `utilities-osx-queue-populator/m2-virtual-mic-and-memo-review`
Milestone summary: first major feature build-out on top of the imported base — virtual microphone routing, voice-memo capture/review, app icon/assets, and a driver install path for the virtual mic kernel/driver pieces.

### Added
- `VirtualMicRouter` + `MicTarget` + `AudioDeviceLookup`: route captured audio to a virtual mic device
- `MemoAudioRecorder`: voice-memo audio capture/export
- `MemoReviewWindow`: UI to review captured memos
- `PhraseDetector`: recognition-driven phrase/command detection
- `Driver/build-virtual-mics.sh`, `Driver/uninstall-virtual-mics.sh`, `Driver/README.md`: virtual mic driver install/uninstall tooling
- App icon set and status bar icon assets (`Assets/QueuePopulator.iconset`, `StatusIcon.png`)
- `QueuePopulatorConfig` app-level configuration
- `AppEvent` / expanded `AppState` for the new state machine transitions

### Changed
- `Coordinator` substantially expanded to wire virtual mic routing, memo recording, and phrase detection into the existing flow
- `TranscriptWindow`, `ConfigDialog`, `StatusBarController` reworked to support the new memo review and state machine paths
- `WindowActivation`, `AppIcon`, `StateOverlay` added/updated for window/menu-bar presentation

## [m1-initial-import] — 2026-06-13 — tag: `utilities-osx-queue-populator/m1-initial-import`
Milestone summary: subtree-imported the base Swift menu-bar app — speech recognition via `SpeechEngine`, LLM-backed queue population via `LlmClient`, and the initial `Coordinator` orchestrating state.

### Added
- `SpeechEngine` (macOS Speech framework wrapper) and mic `Permissions`
- `LlmClient` / `LlmResponse` for LLM-backed request handling
- `Coordinator` orchestrating recognition → LLM → queue flow
- `AppConfig`, `ConfigStore`, `LlmConfig` initial configuration model
- `Makefile`, `Package.swift`, base `README.md`
