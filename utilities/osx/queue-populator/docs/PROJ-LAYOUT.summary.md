# Project Layout — Summary

```
queue-populator/
├── Sources/                        # Swift app source
│   ├── main.swift                  #   Entry point
│   ├── Coordinator.swift           #   Top-level wiring
│   ├── Audio/                      #   Mic capture, speech-to-text, virtual mic routing
│   ├── Config/                     #   Config, secrets, logging
│   ├── LLM/                        #   LLM classification client
│   ├── Queue/                      #   JSONL queue output
│   ├── Recognition/                #   Wake-phrase detection
│   ├── StateMachine/               #   App lifecycle state machine
│   └── UI/                         #   Menu bar + windows (AppKit)
├── Driver/                         # Virtual mic driver build/uninstall scripts
├── Probes/MenuOnlyProbe/           # Diagnostic probe harness
├── Assets/                         # Icons (icns, iconset, PNGs)
├── docs/                           # PROJ-ARCH.md, PROJ-LAYOUT.md + summaries
├── com.noizu.queue-populator.plist # launchd agent
├── queue-populator.entitlements    # macOS entitlements
├── Package.swift                   # SwiftPM manifest
├── Makefile                        # Build shortcuts
├── install.sh / uninstall.sh       # Install/remove app + launchd agent
└── README.md                       # Overview
```
