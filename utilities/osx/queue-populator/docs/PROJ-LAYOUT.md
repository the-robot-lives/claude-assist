# Project Layout

macOS menu bar utility (Swift Package Manager executable) that captures voice/CLI input, transcribes it, classifies it via an LLM, and routes entries to `~/personal-development/queue/*.jsonl`. Also feeds live mic audio into virtual microphone devices (Recording / Claude / Codex / Llama) for other apps.

```
queue-populator/
├── Sources/                            # Swift app source (single executable target)
│   ├── main.swift                      #   Entry point — app bootstrap
│   ├── Coordinator.swift               #   Top-level wiring of audio, state machine, UI, queue
│   ├── Audio/                          #   Mic capture, speech-to-text, virtual mic routing
│   │   ├── AudioDeviceLookup.swift     #     CoreAudio device discovery
│   │   ├── MemoAudioRecorder.swift     #     Voice memo capture
│   │   ├── MicTarget.swift             #     Virtual mic target definitions
│   │   ├── Permissions.swift           #     Mic/speech permission prompts
│   │   ├── SpeechEngine.swift          #     Speech recognition (transcription)
│   │   └── VirtualMicRouter.swift      #     Routes live mic → virtual mic devices
│   ├── Config/                         #   Configuration, secrets, logging
│   │   ├── AppConfig.swift             #     App-level settings
│   │   ├── BuildInfo.swift             #     Build metadata
│   │   ├── ConfigStore.swift           #     Config persistence
│   │   ├── DebugLog.swift              #     Debug logging
│   │   ├── EnvResolver.swift           #     Env var resolution
│   │   ├── LlmConfig.swift             #     LLM provider/model settings
│   │   ├── QueuePopulatorConfig.swift  #     Main config model
│   │   └── SecretStore.swift           #     API key / secret storage
│   ├── LLM/                            #   LLM classification client
│   │   ├── LlmClient.swift             #     HTTP client for LLM API
│   │   ├── LlmResponse.swift           #     Response models
│   │   ├── ModelFetcher.swift          #     Available-model listing
│   │   └── PromptBuilder.swift         #     Classification prompt assembly
│   ├── Queue/                          #   JSONL queue output
│   │   ├── QueueEntry.swift            #     Entry record model
│   │   ├── QueueManifest.swift         #     Queue file routing manifest
│   │   └── QueueWriter.swift           #     Appends entries to .jsonl files
│   ├── Recognition/                    #   Wake-phrase detection
│   │   └── PhraseDetector.swift        #     Trigger phrase matching
│   ├── StateMachine/                   #   App lifecycle state machine
│   │   ├── AppEvent.swift              #     Events
│   │   ├── AppState.swift              #     States
│   │   └── AppStateMachine.swift       #     Transitions
│   └── UI/                             #   Menu bar + windows (AppKit)
│       ├── AppIcon.swift               #     Icon handling
│       ├── BlockTarget.swift           #     UI action targets
│       ├── ConfigDialog.swift          #     Settings dialog
│       ├── MemoReviewWindow.swift      #     Voice memo review
│       ├── ReviewWindow.swift          #     Entry review/confirm
│       ├── StateOverlay.swift          #     On-screen state indicator
│       ├── StatusBarController.swift   #     Menu bar item + menu
│       ├── TranscriptWindow.swift      #     Live transcript display
│       └── WindowActivation.swift      #     Window focus helpers
├── Driver/                             # Virtual microphone driver setup
│   ├── README.md                       #   Driver install/usage notes
│   ├── build-virtual-mics.sh           #   Builds/installs virtual mic devices
│   └── uninstall-virtual-mics.sh       #   Removes virtual mic devices
├── Probes/                             # Standalone diagnostic probes
│   └── MenuOnlyProbe/main.swift        #   Minimal menu-bar-only test harness
├── Assets/                             # Icons and image assets
│   ├── QueuePopulator.icns             #   App icon bundle
│   ├── QueuePopulator.iconset/         #   Icon source PNGs (16–512px)
│   ├── StatusIcon.png                  #   Menu bar status icon
│   ├── queue-populator-icon.png        #   Source icon image
│   └── queue-populator-icon-response.json  # Icon generation response record
├── docs/                               # Documentation
│   ├── PROJ-ARCH.md                    #   Architecture doc
│   ├── PROJ-ARCH.summary.md            #   Architecture quick reference
│   ├── PROJ-LAYOUT.md                  #   This file — project structure map
│   └── PROJ-LAYOUT.summary.md          #   Quick-reference tree for tools/agents
├── com.noizu.queue-populator.plist     # launchd agent definition (login autostart)
├── queue-populator.entitlements        # macOS entitlements (mic, speech)
├── Package.swift                       # SwiftPM manifest (executable target)
├── Makefile                            # Build shortcuts
├── install.sh                          # Build + install app and launchd agent
├── uninstall.sh                        # Remove app and launchd agent
├── .gitignore                          # Excludes .build/, .swiftpm/, .env, etc.
└── README.md                           # Overview — channels, routing logic, entry format
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `install.sh` | Run to build and install app + launchd agent |
| `Driver/build-virtual-mics.sh` | Run to create virtual microphone devices |
| LLM API key | Configured at runtime via ConfigDialog / SecretStore |

## Notes

- Build artifacts (`.build/`, `.swiftpm/`, `Package.resolved`) are gitignored.
- `Probes/` contains throwaway diagnostic binaries, not part of the main target.
- A Linux port exists separately (PipeWire-based); this is the macOS original.
